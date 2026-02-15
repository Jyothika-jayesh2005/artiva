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

/**
 * Main Auction Lifecycle Cron
 * Runs every 1 minute to check for:
 * 1. Auctions that just ended -> Mark winner / pending payment
 * 2. Payment reminders -> 2h before deadline
 * 3. Payment deadlines -> Cancel / Re-award
 */
exports.checkAuctionStatus = onSchedule("every 1 minutes", async (event) => {
  const now = admin.firestore.Timestamp.now();

  try {
    await handleEndedAuctions(now);
    await handlePaymentReminders(now);
    await handlePaymentDeadlines(now);
  } catch (e) {
    logger.error("Error in checkAuctionStatus", e);
  }
});

async function notifyAdmin(title, body, type, auctionId, now) {
  try {
    await db.collection("admin_notifications").add({
      title,
      body,
      type,
      auctionId,
      read: false,
      createdAt: now,
    });
  } catch (e) {
    logger.error("Failed to notify admin", e);
  }
}

async function handleEndedAuctions(now) {
  // Find auctions that match:
  // status IN ['live', 'scheduled'] AND endTime < now
  const snap = await db.collection("auctions")
    .where("status", "in", ["live", "scheduled"])
    .where("endTime", "<", now)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  let updatesCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const highestBidderId = data.highestBidderId;
    const currentBid = data.currentBid || 0;
    const artTitle = data.artTitle || "Artwork";

    if (highestBidderId) {
      // Case: Winner exists
      const deadline = new Date(now.toDate().getTime() + 12 * 60 * 60 * 1000); // +12 hours

      batch.update(doc.ref, {
        status: "pending_payment",
        paymentDueAt: admin.firestore.Timestamp.fromDate(deadline),
        reminderSent: false,
        finalPrice: currentBid,
      });

      // Notification to Winner
      const notifRef = db.collection("users").doc(highestBidderId).collection("notifications").doc();
      batch.set(notifRef, {
        title: "🎉 You Won!",
        body: `You won ${artTitle} at ₹${currentBid}. Please complete payment before ${deadline.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.`,
        type: "win",
        auctionId: doc.id,
        read: false,
        createdAt: now,
      });

      // Notify Admin
      await notifyAdmin(
        "Auction Sold",
        `${artTitle} sold to ${data.highestBidderName || 'User'} for ₹${currentBid}. Waiting for payment.`,
        "auction_sold",
        doc.id,
        now
      );

      updatesCount++;
    } else {
      // Case: No bids -> Unsold
      batch.update(doc.ref, {
        status: "unsold",
        finalPrice: data.startingBid,
        paymentDueAt: null,
      });

      // Notify Admin
      await notifyAdmin(
        "Auction Unsold",
        `${artTitle} ended with no bids.`,
        "auction_unsold",
        doc.id,
        now
      );

      updatesCount++;
    }
  }

  if (updatesCount > 0) {
    await batch.commit();
    logger.info(`Processed ${updatesCount} ended auctions.`);
  }
}

async function handlePaymentReminders(now) {
  // Find auctions where:
  // status == 'pending_payment'
  // reminderSent == false
  // paymentDueAt <= now + 2 hours
  const twoHoursLater = new Date(now.toDate().getTime() + 2 * 60 * 60 * 1000);
  const twoHoursLaterTs = admin.firestore.Timestamp.fromDate(twoHoursLater);

  const snap = await db.collection("auctions")
    .where("status", "==", "pending_payment")
    .where("reminderSent", "==", false)
    .where("paymentDueAt", "<=", twoHoursLaterTs)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  let updatesCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const winnerId = data.highestBidderId;
    const artTitle = data.artTitle || "Artwork";

    if (winnerId) {
      batch.update(doc.ref, { reminderSent: true });

      const notifRef = db.collection("users").doc(winnerId).collection("notifications").doc();
      batch.set(notifRef, {
        title: "⚠ Final Reminder",
        body: `Payment due for ${artTitle}. If not paid, your win will be cancelled.`,
        type: "reminder",
        auctionId: doc.id,
        read: false,
        createdAt: now,
      });

      updatesCount++;
    }
  }

  if (updatesCount > 0) {
    await batch.commit();
    logger.info(`Sent ${updatesCount} payment reminders.`);
  }
}

async function handlePaymentDeadlines(now) {
  // Find auctions where:
  // status == 'pending_payment'
  // paymentDueAt < now
  const snap = await db.collection("auctions")
    .where("status", "==", "pending_payment")
    .where("paymentDueAt", "<", now)
    .get();

  if (snap.empty) return;

  // Process one by one because we need to query subcollections (bids)
  // which can't be done easily in a single batch for all different auctions
  // But we can batch the writes for each auction.

  for (const doc of snap.docs) {
    const data = doc.data();
    const oldWinnerId = data.highestBidderId;
    const artTitle = data.artTitle || "Artwork";
    const oldWinnerName = data.highestBidderName || "User";

    // 1. Notify Old Winner (Forfeit)
    if (oldWinnerId) {
      await db.collection("users").doc(oldWinnerId).collection("notifications").add({
        title: "❌ Win Cancelled",
        body: `Your win for ${artTitle} has been cancelled due to non-payment.`,
        type: "reminder", // reusing this type or could add 'cancellation'
        auctionId: doc.id,
        read: false,
        createdAt: now,
      });
    }

    // 2. Find Next Highest Bidder
    // We need to exclude the current highest bidder from the candidates
    // But since we store bids in a subcollection, we query them.
    // NOTE: In a real robust system, we might want to flag the bid as 'failed' so we don't pick it again.
    // Here we'll just look for the next highest bid that is NOT the current winner.

    const bidsSnap = await db.collection("auctions").doc(doc.id).collection("bids")
      .orderBy("amount", "desc")
      .get();

    let nextWinnerBid = null;

    // Iterate to find the first bidder who is NOT the oldWinnerId
    for (const bidDoc of bidsSnap.docs) {
      const bidData = bidDoc.data();
      if (bidData.userId !== oldWinnerId) {
        // Found the second highest distinct bidder
        // check if this user has already failed before? 
        // For simplicity, we assume this is the first re-award or we just pick the next valid one.
        nextWinnerBid = bidData;
        break;
      }
    }

    if (nextWinnerBid) {
      // Case A: Second Bidder Exists
      const newDeadline = new Date(now.toDate().getTime() + 12 * 60 * 60 * 1000);

      await doc.ref.update({
        highestBidderId: nextWinnerBid.userId,
        highestBidderName: nextWinnerBid.userName,
        currentBid: nextWinnerBid.amount,
        finalPrice: nextWinnerBid.amount,
        paymentDueAt: admin.firestore.Timestamp.fromDate(newDeadline),
        reminderSent: false,
        status: "pending_payment", // remain in pending payment
      });

      // Notify New Winner
      await db.collection("users").doc(nextWinnerBid.userId).collection("notifications").add({
        title: "🎉 Use Second Chance Offer!",
        body: `The previous winner did not pay. You can now purchase ${artTitle} at ₹${nextWinnerBid.amount}. Complete payment within 12 hours.`,
        type: "win",
        auctionId: doc.id,
        read: false,
        createdAt: now,
      });

      // Notify Admin
      await notifyAdmin(
        "Winner Re-awarded",
        `Previous winner ${oldWinnerName} failed to pay. ${artTitle} re-awarded to ${nextWinnerBid.userName}.`,
        "auction_reawarded",
        doc.id,
        now
      );

      logger.info(`Re-awarded auction ${doc.id} to ${nextWinnerBid.userId}`);

    } else {
      // Case B: No Second Bidder -> Unsold
      await doc.ref.update({
        status: "unsold",
        paymentDueAt: null,
        finalPrice: data.startingBid,
        highestBidderId: null, // Clear winner
        highestBidderName: null,
      });

      // Notify Admin
      await notifyAdmin(
        "Auction Unsold (Non-payment)",
        `Winner ${oldWinnerName} failed to pay and no other bids exist for ${artTitle}.`,
        "auction_unsold",
        doc.id,
        now
      );

      logger.info(`Marked auction ${doc.id} as unsold (non-payment, no other bids).`);
    }
  }
}
