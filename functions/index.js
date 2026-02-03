const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const admin = require("firebase-admin");
if (admin.apps.length === 0) admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

exports.health = onRequest((req, res) => {
  logger.info("Health check called", { method: req.method, path: req.path });
  res.status(200).json({ ok: true, message: "Functions are running" });
});

exports.onOrderRated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before?.data() || {};
  const after = event.data?.after?.data();
  if (!after) return;

  // Run only when ratingLocked flips false -> true
  const becameLocked = (before.ratingLocked !== true) && (after.ratingLocked === true);
  if (!becameLocked) return;

  // If admin deleted review, do nothing
  if (after.reviewDeleted === true) return;

  const artId = (after.artId || "").toString().trim();
  const uid = (after.userId || "").toString().trim();
  const email = (after.customerEmail || "").toString().trim();
  const rating = after.rating;
  const review = (after.review || "").toString();
  const orderId = event.params.orderId;

  if (!artId || !uid) return;
  if (typeof rating !== "number" || rating < 1 || rating > 5) return;

  const artRef = db.collection("artworks").doc(artId);
  const ratingRef = artRef.collection("user_ratings").doc(orderId);

  await db.runTransaction(async (tx) => {
    // write public review
    tx.set(
      ratingRef,
      {
        uid,
        email,
        rating,
        review,
        orderId,
        ratedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // update stats
    const artSnap = await tx.get(artRef);
    const art = artSnap.exists ? artSnap.data() : {};

    const oldAvg = Number(art?.avgRating ?? 0);
    const oldCount = Number(art?.ratingCount ?? 0);

    const newCount = oldCount + 1;
    const newAvg = ((oldAvg * oldCount) + rating) / newCount;

    tx.set(
      artRef,
      {
        avgRating: newAvg,
        ratingCount: newCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
});

/**
 * Automatically archive exhibitions every day at midnight.
 * NOTE: Requires Blaze (Pay-as-you-go) plan.
 */
exports.archiveOldExhibitions = onSchedule("0 0 * * *", async (event) => {
  const now = admin.firestore.Timestamp.now();
  const snap = await db.collection("exhibitions")
    .where("isArchived", "==", false)
    .where("dateTime", "<", now)
    .get();

  if (snap.empty) {
    logger.info("No exhibitions to archive.");
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      isArchived: true,
      updatedAt: now,
    });
  });

  await batch.commit();
  logger.info(`Archived ${snap.size} exhibitions.`);
});
