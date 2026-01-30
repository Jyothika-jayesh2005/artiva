# Code Changes Summary

## File 1: lib/backend/backend_service.dart

### Change 1: Added new method `getArtworkReviews()`
```dart
Future<List<ArtworkOrder>> getArtworkReviews(String artworkId) async {
  final snap = await _db
      .collection('orders')
      .where('artId', isEqualTo: artworkId)
      .where('ratingLocked', isEqualTo: true)
      .orderBy('ratedAt', descending: true)
      .get();

  return snap.docs
      .map(_orderFromDoc)
      .where((order) => order.rating != null || (order.review ?? "").trim().isNotEmpty)
      .toList();
}
```
**Purpose**: Fetch all approved reviews for an artwork to display on detail page

### Change 2: Updated `submitOrderRating()` method
**Added checks:**
- ✅ Verify order status is "delivered"
- ✅ Check if `reviewDeleted == true` (prevents review after admin deletion)
- ✅ Check if `ratingLocked == true` (prevents duplicate reviews)

**Key additions:**
```dart
// ✅ REQUIREMENT 3: If admin deleted review, customer cannot review again
if (reviewDeleted) {
  throw Exception("Your previous review was removed by admin. You cannot submit another review.");
}
```

### Change 3: Updated `deleteOrderReview()` method
**Enhanced to:**
1. Set `reviewDeleted: true` flag (prevents future reviews)
2. Recalculate average rating (subtracts the deleted rating)
3. Remove from user_ratings subcollection
4. Use transaction for consistency

**Key addition:**
```dart
// ✅ Mark as deleted so customer cannot review again
'reviewDeleted': true,  // NEW: Track that review was deleted
```

---

## File 2: lib/customer/artwork_detail.dart

### Change 1: Added "Customer Ratings" section
**Location**: Before the bottom "Buy Now" bar
**Code**:
```dart
const SizedBox(height: 32),

// ✅ CUSTOMER RATINGS SECTION
const Text(
  "Customer Ratings",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 12),
_buildCustomerRatingsSection(),

const SizedBox(height: 32),
```

### Change 2: Added 4 new methods for ratings display

#### Method 1: `_buildCustomerRatingsSection()`
- Uses FutureBuilder to load reviews asynchronously
- Shows "No ratings yet" if empty
- Displays list of review cards

#### Method 2: `_buildReviewCard()`
- Shows individual review with:
  - Star rating (visual + text score)
  - Customer name
  - Review text (truncated to 4 lines)
  - Relative date (e.g., "2d ago")

#### Method 3: `_buildStarsRow()`
- Renders 5 stars (filled or empty based on rating)

#### Method 4: `_formatReviewDate()`
- Converts timestamp to relative format
- Examples: "1h ago", "2d ago", "3mo ago"

---

## File 3: lib/customer/profile/my_orders.dart

### Change 1: Enhanced "Rate This Order" button
**Before:**
```dart
child: Text(
  _busy ? "PLEASE WAIT..." : "Rate This Order",
  style: const TextStyle(color: Colors.white),
),
```

**After:**
```dart
style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFE16417),
  disabledBackgroundColor: Colors.grey.shade400,  // ← NEW
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
child: Text(
  _busy ? "PLEASE WAIT..." : "Rate This Order",
  style: TextStyle(
    color: _busy ? Colors.black54 : Colors.white,  // ← NEW
    fontWeight: FontWeight.w600,  // ← NEW
  ),
),
```

**Purpose**: Shows disabled state when button is not clickable

---

## Data Flow Diagram

### Submission Flow:
```
User clicks "Rate This Order"
    ↓
Dialog opens with star selector
    ↓
User selects rating + optional review
    ↓
User clicks "Submit"
    ↓
Button set to disabled (_busy = true)
    ↓
Backend validation:
  ✓ Order status = "delivered"?
  ✓ ratingLocked = false?
  ✓ reviewDeleted = false?
    ↓
All pass → Save to database
    ↓
Recalculate average rating
    ↓
Update local state
    ↓
Display review on ArtworkDetailPage
    ↓
Button remains disabled (can't submit again)
```

### Deletion Flow:
```
Admin clicks delete on review
    ↓
Backend:
  - Sets reviewDeleted = true
  - Removes rating/review/ratedAt
  - Recalculates average
  - Removes from user_ratings
    ↓
Customer sees error on next attempt:
"Your previous review was removed by admin..."
```

---

## Database Schema Updates

### orders collection
```javascript
{
  // ... existing fields ...
  status: "delivered",           // MUST be "delivered"
  ratingLocked: true,            // Set after submission
  reviewDeleted: false,          // ← NEW: Set by admin delete
  rating: 5,                     // 1-5
  review: "Great artwork!",      // Optional
  ratedAt: Timestamp.now(),      // When submitted
}
```

### artworks collection
```javascript
{
  // ... existing fields ...
  avgRating: 4.5,               // Updated after each review
  ratingCount: 12,              // Updated after each review
}
```

---

## Error Handling

### Backend throws these errors:

```
"You can rate only after the order is delivered."
→ User tries to rate non-delivered order

"You already rated this order."
→ User tries to rate twice (ratingLocked = true)

"Your previous review was removed by admin. You cannot submit another review."
→ User tries to rate after admin deletion (reviewDeleted = true)

"Rating must be between 1 and 5."
→ Invalid rating value
```

All errors caught and displayed to user via snackbar

---

## No Breaking Changes

✅ All existing code preserved
✅ Only additions and enhancements
✅ No database schema deletions
✅ Backward compatible
✅ No new dependencies

---

**Implementation Complete**: ✅
**Testing Status**: Ready
**Deployment**: Safe to merge
