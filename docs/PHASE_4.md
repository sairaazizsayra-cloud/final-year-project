# Phase 4 Completion Report

## Completed

- Cart (Firestore `cart/{userId}/items`) with quantity update / remove / clear
- `CartProvider` + cart badge on bottom nav
- Product details: **Add to Cart** and **Buy Now**
- Addresses CRUD for home-to-home delivery
- Checkout: address selection, COD, online payment entry point, order summary
- Order create in Firestore `orders`
- Order success screen
- `PaymentService` calls Cloud Function `createPaymentSession` (no fake success)
- Cloud Function stub `createPaymentSession` (returns not-configured until gateway is added)

## Routes

| Path | Screen |
|------|--------|
| `/cart` | Cart |
| `/checkout` | Checkout |
| `/order-success/:orderId` | Success |
| `/addresses` | Address list (`?select=1` for checkout) |
| `/addresses/form` | Add / edit address |

## Delivery charges

- Default: `Rs 150` (`AppConstants.defaultDeliveryCharges`)
- Free when subtotal ≥ `Rs 2000`

## Test

1. Open a product → Add to Cart → Cart tab
2. Profile → Addresses → add a home address
3. Checkout → Cash on Delivery → Place order
4. Confirm order appears in Firestore `orders`
5. Online Payment shows a clear “not configured” message (no fake paid status)

## Next: Phase 5

Orders list, tracking timeline, notifications, delivery assignment.

Reply **"continue Phase 5"** when ready.
