/// App-wide constants for Keychain Shop.
class AppConstants {
  AppConstants._();

  static const String appName = 'Keychain Shop';
  static const String appTagline = 'Custom Keychains. Delivered Home.';

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';
  static const String roleRider = 'rider';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String cartCollection = 'cart';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'orderItems';
  static const String addressesCollection = 'addresses';
  static const String favoritesCollection = 'favorites';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';
  static const String paymentsCollection = 'payments';
  static const String deliveriesCollection = 'deliveries';
  static const String couponsCollection = 'coupons';
  static const String bannersCollection = 'banners';

  // Storage paths
  static const String productImagesPath = 'products';
  static const String categoryImagesPath = 'categories';
  static const String profileImagesPath = 'profiles';
  static const String customKeychainImagesPath = 'custom_keychains';
  static const String bannerImagesPath = 'banners';

  // Order statuses
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderPreparing = 'preparing';
  static const String orderShipped = 'shipped';
  static const String orderOutForDelivery = 'out_for_delivery';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  static const List<String> orderStatusFlow = [
    orderPending,
    orderConfirmed,
    orderPreparing,
    orderShipped,
    orderOutForDelivery,
    orderDelivered,
  ];

  // Payment
  static const String paymentCod = 'cash_on_delivery';
  static const String paymentOnline = 'online';
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // Delivery
  static const double defaultDeliveryCharges = 150.0;
  static const double freeDeliveryThreshold = 2000.0;

  // Shared preferences keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefFcmToken = 'fcm_token';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxCartQuantity = 99;
}
