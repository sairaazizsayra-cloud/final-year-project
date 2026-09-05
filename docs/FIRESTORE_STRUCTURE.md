# Firestore Database Structure — Keychain Shop

## Collections overview

```text
users
admins
products
categories
cart/{userId}/items/{productId}
orders
orderItems
addresses
favorites
reviews
notifications
payments
deliveries
coupons
banners
```

## users/{userId}

| Field | Type | Notes |
|-------|------|--------|
| name | string | |
| email | string | |
| phone | string? | |
| profileImage | string? | Storage download URL |
| role | string | `customer` \| `admin` \| `rider` |
| createdAt | timestamp | |
| updatedAt | timestamp? | |
| isActive | bool | |
| fcmToken | string? | |

## products/{productId}

| Field | Type | Notes |
|-------|------|--------|
| name | string | |
| nameLower | string | For prefix search |
| description | string | |
| categoryId | string | |
| categoryName | string? | Denormalized |
| price | number | |
| discount | number | Percent 0–100 |
| stock | number | Admin / Functions only |
| images | string[] | Storage URLs |
| material | string? | |
| size | string? | |
| colors | string[] | |
| isCustomizable | bool | |
| rating | number | Aggregate |
| totalReviews | number | |
| isFeatured | bool | |
| isBestSeller | bool | |
| isNewArrival | bool | |
| isActive | bool | |
| createdAt | timestamp | |
| updatedAt | timestamp? | |

## categories/{categoryId}

| Field | Type |
|-------|------|
| name | string |
| description | string? |
| imageUrl | string? |
| sortOrder | number |
| isActive | bool |
| createdAt | timestamp |

## cart/{userId}/items/{itemId}

| Field | Type |
|-------|------|
| productId | string |
| productName | string |
| productImage | string? |
| price | number |
| discount | number |
| quantity | number |
| selectedColor | string? |
| selectedSize | string? |
| customText | string? |
| customImageUrl | string? |
| addedAt | timestamp |

## addresses/{addressId}

| Field | Type |
|-------|------|
| userId | string |
| fullName | string |
| phone | string |
| houseStreet | string |
| area | string |
| city | string |
| postalCode | string |
| isDefault | bool |
| createdAt | timestamp |

## orders/{orderId}

| Field | Type | Notes |
|-------|------|--------|
| userId | string | |
| userName | string? | |
| userEmail | string? | |
| userPhone | string? | |
| items | array | Line-item snapshots |
| subtotal | number | |
| deliveryCharges | number | |
| discount | number | |
| totalAmount | number | |
| couponCode | string? | |
| paymentMethod | string | `cash_on_delivery` \| `online` |
| paymentStatus | string | `pending` \| `paid` \| `failed` \| `refunded` |
| orderStatus | string | See flow below |
| deliveryAddress | map | Snapshot at checkout |
| deliveryId | string? | |
| riderId | string? | |
| notes | string? | |
| createdAt | timestamp | |
| updatedAt | timestamp? | |
| estimatedDeliveryDate | timestamp? | |
| deliveredAt | timestamp? | |
| statusHistory | array | `{status, timestamp, note}` |

### Order status flow

```text
pending → confirmed → preparing → shipped → out_for_delivery → delivered
                                                              ↘ cancelled
```

## favorites/{favoriteId}

| Field | Type |
|-------|------|
| userId | string |
| productId | string |
| createdAt | timestamp |

## reviews/{reviewId}

| Field | Type |
|-------|------|
| productId | string |
| userId | string |
| userName | string? |
| userImage | string? |
| orderId | string? |
| rating | number | 1–5 |
| comment | string |
| images | string[] |
| isApproved | bool |
| createdAt | timestamp |

## notifications/{notificationId}

| Field | Type |
|-------|------|
| userId | string |
| title | string |
| body | string |
| type | string | order / promo / product / general |
| orderId | string? |
| productId | string? |
| data | map? |
| isRead | bool |
| createdAt | timestamp |

## deliveries/{deliveryId}

| Field | Type |
|-------|------|
| orderId | string |
| userId | string |
| riderId | string? |
| riderName | string? |
| deliveryAddress | map |
| status | string |
| notes | string? |
| assignedAt | timestamp |
| deliveredAt | timestamp? |

## coupons/{couponId}

| Field | Type |
|-------|------|
| code | string | Uppercase |
| description | string |
| discountType | string | `percentage` \| `fixed` |
| discountValue | number |
| minOrderAmount | number |
| maxDiscount | number? |
| usageLimit | number | 0 = unlimited |
| usedCount | number |
| validFrom | timestamp |
| validUntil | timestamp |
| isActive | bool |

## payments/{paymentId}

Written only by Cloud Functions after gateway verification.

| Field | Type |
|-------|------|
| userId | string |
| orderId | string |
| amount | number |
| method | string |
| status | string |
| transactionId | string? |
| createdAt | timestamp |

## Storage paths

```text
products/{productId}/{fileName}
categories/{categoryId}.jpg
profiles/{userId}.jpg
custom_keychains/{userId}/{fileName}
banners/{bannerId}.jpg
```

Firestore stores **download URLs only**, never binary image data.
