import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

enum AppLang { en, ar }

extension AppLangExt on AppLang {
  String get code => switch (this) {
        AppLang.en => 'en',
        AppLang.ar => 'ar',
      };
  String get label => switch (this) {
        AppLang.en => 'English',
        AppLang.ar => 'العربية',
      };
  TextDirection get direction => switch (this) {
        AppLang.en => TextDirection.ltr,
        AppLang.ar => TextDirection.rtl,
      };
}

/// Persisted, app-wide locale controller.
/// Change locale anywhere with `LocaleController.of(context).setLang(...)`.
class LocaleController extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_lang';

  AppLang _lang = AppLang.en;
  AppLang get lang => _lang;

  bool get isArabic => _lang == AppLang.ar;
  Locale get locale => Locale(_lang.code);
  TextDirection get textDirection => _lang.direction;

  LocaleController();

  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    _apply(saved == 'ar' ? AppLang.ar : AppLang.en);
  }

  Future<void> setLang(AppLang lang) async {
    await _storage.write(key: _key, value: lang.code);
    _apply(lang);
  }

  void _apply(AppLang lang) {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
  }

  static LocaleController of(BuildContext context, {bool listen = true}) =>
      Provider.of<LocaleController>(context, listen: listen);
}

/// Typed bilingual string bundle. Usage: `S.of(context).makeOrder`.
class S {
  final AppLang lang;
  const S(this.lang);

  factory S.of(BuildContext context) =>
      S(LocaleController.of(context, listen: false).lang);

  String t(String en, String ar) => lang == AppLang.ar ? ar : en;

  bool get isArabic => lang == AppLang.ar;

  // ---- App shell ----
  String get title => t('Naql', 'ناقل');
  String get customer => t('Customer', 'عميل');
  String get notifications => t('🔔', '🔔');

  // ---- Cargo ----
  String get cargoStep => t('Cargo type', 'نوع الشحنة');
  String get cargoStepHint => t(
        'What are you moving?',
        'ماذا تقلّب؟',
      );
  String get homeFurniture => t('Home Furniture', 'عفش منزلي');
  String get homeFurnitureSub => t(
        'Household items, furniture & more',
        'أثاث، أغراض منزلية ومزيد',
      );
  String get appliances => t('Appliances', 'أجهزة');
  String get appliancesSub => t(
        'Fridges, TVs & electronics',
        'ثلاجات، شاشات وإلكترونيات',
      );
  String get recommended => t('Recommended', 'مقترح');

  // ---- Vehicle ----
  String get chooseVehicle => t('Choose a vehicle', 'اختر العربة');
  String get selectVehicleHint => t(
        'Select the right size for your shipment.',
        'اختر الحجم المناسب لشحنتك.',
      );
  String get vehicleLabel => t('Vehicle', 'العربة');
  String get capacity => t('Capacity', 'السعة');
  String get price => t('Price', 'السعر');
  String get truckSizeGuide => t('Truck sizes', 'أحجام العربات');

  // ---- Locations ----
  String get locationsStep => t('Pickup & drop-off', 'نقطة الاستلام والتوصيل');
  String get locationsHint => t('Enter addresses.', 'أدخل العناوين.');
  String get pickup => t('Pickup', 'نقطة الاستلام');
  String get dropoff => t('Drop-off', 'نقطة التوصيل');
  String get pickupAddress => t('Pickup address', 'عنوان الاستلام');
  String get dropoffAddress => t('Drop-off address', 'عنوان التوصيل');
  String get selectCity => t('Select a city', 'اختر المدينة');
  String get selectCityHint => t('Search a city...', 'ابحث عن مدينة...');
  String get fullAddress => t('Full address', 'العنوان الكامل');
  String get fullAddressHint => t('Street, building, floor...', 'الشارع، العنمود، الطابق...');
  String get pickOnMap => t('Pick on map', 'اختر على الخريطة');

  // ---- Schedule ----
  String get scheduleStep => t('When do you need it?', 'متى تحتاجها؟');
  String get scheduleHint => t(
        'Choose instant dispatch or schedule ahead.',
        'اختر الإرسال الفوري أو الجدولة.',
      );
  String get bookNow => t('Book Now', 'احجز الآن');
  String get bookNowSub => t('Instant dispatch', 'إرسال فوري');
  String get schedule => t('Schedule', 'جدولة');
  String get scheduleSub => t('Pick a date & time', 'اختر تاريخ ووقت');
  String get selectDate => t('Select date', 'اختر التاريخ');
  String get selectTime => t('Select time', 'اختر الوقت');

  // ---- Budget ----
  String get budgetStep => t('Set your budget', 'حدد ميزانيتك');
  String get budgetHint => t(
        'What is the maximum you are willing to pay?',
        'أقصى مبلغ مرتاح لدفعه؟',
      );
  String get minEgp => t('Min EGP', 'أدنى سعر');
  String get maxEgp => t('Max EGP', 'أقصى سعر');
  String get egp => t('EGP', 'ج.م');

  // ---- Payment ----
  String get paymentStep => t('Payment method', 'طريقة الدفع');
  String get paymentHint => t(
        'Choose how you would like to pay.',
        'كيف تفضل تدفع؟',
      );
  String get cash => t('Cash', 'نقدًا');
  String get visa => t('Visa', 'فيزا');
  String get cardNumber => t('Card number', 'رقم البطاقة');
  String get expiry => t('Expiry', 'انتهاء الصلاحية');
  String get cvv => t('CVV', 'CVV');
  String get paymentNote => t(
        'Payment is not available yet. Approved requests remain pending payment.',
        'الدفع غير متاح بعد. الطلبات المعتمدة تبقى معلقة في الدفع.',
      );

  // ---- Confirm ----
  String get confirmStep => t('Confirm your request', 'تأكيد طلبك');
  String get confirmHint => t(
        'Review everything before submitting.',
        'راجع كل شيء قبل الإرسال.',
      );
  String get scheduleLabel => t('Schedule', 'الجدول');
  String get budgetLabel => t('Budget', 'الميزانية');
  String get paymentLabel => t('Payment', 'الدفع');
  String get unknown => t('Unknown', 'غير معروف');
  String get now => t('Now', 'الآن');

  // ---- Navigation / actions ----
  String get back => t('Back', 'رجوع');
  String get goBack => t('Back', 'رجوع');
  String get next => t('Continue', 'متابعة');
  String get submitRequest => t('Submit request', 'إرسال الطلب');
  String get makeOrder => t('Make Order', 'اطلب الآن');
  String get requestTruck => t('Request a truck', 'اطلب عربة');
  String get cancel => t('Cancel', 'إلغاء');

  // ---- Snackbars / errors ----
  String get completeFields => t(
        'Please complete all required fields.',
        'الرجاء إكمال جميع الحقول المطلوبة.',
      );
  String get requestSubmitted => t(
        'Request submitted for provider review.',
        'تم إرسال الطلب للمراجعة.',
      );

  // ---- Auth ----
  String get welcomeBack => t('Welcome Back', 'مرحباً بعودتك');
  String get joinNaql => t('Join Naql', 'انضم إلى ناقل');
  String get usernameOrEmail => t('Username or Email', 'اسم المستخدم أو البريد');
  String get emailAddress => t('Email address', 'البريد الإلكتروني');
  String get password => t('Password', 'كلمة المرور');
  String get loginBtn => t('Login', 'تسجيل الدخول');
  String get registerBtn => t('Register', 'إنشاء حساب');
  String get createAccount => t('Create an account', 'إنشاء حساب');
  String get alreadyHave => t('Already have an account?', 'لديك حساب بالفعل؟');
  String get signInFailed => t('Sign-in failed', 'فشل تسجيل الدخول');
  String get registerFailed => t(
        'Registration failed. Use a unique email, username, and a 12+ character password.',
        'فشل إنشاء الحساب. استخدم بريد ومستخدم فريدين وكلم مرور 12+ حرف.',
      );

  // ---- Profile ----
  String get paymentMethods => t('Payment Methods', 'طرق الدفع');
  String get paymentMethodsSub => t('Visa ···· 4242 + Cash', 'فيزا ···· 4242 + نقدًا');
  String get savedAddresses => t('Saved Addresses', 'العناوين المحفوظة');
  String get savedAddressesSub => t('Home, Office', 'المنزل، المكتب');
  String get notifications2 => t('Notifications', 'الإشعارات');
  String get notificationsSub => t('All enabled', 'الكل مفعل');
  String get language => t('Language', 'اللغة');
  String get privacy => t('Privacy & Security', 'الخصوصية والأمان');
  String get signOut => t('Sign Out', 'تسجيل الخروج');
  String get editPhone => t('Edit phone', 'تعديل الهاتف');
  String get phone => t('Phone', 'هاتف');
  String get addPhone => t('Add phone', 'إضافة هاتف');
  String get contactInfo => t(
        'Contact information unavailable',
        'معلومات التواصل غير متوفرة',
      );
  String get yourPhone => t('Your phone', 'هاتفك');
  String get enterPhone => t('Enter your phone number', 'أدخل رقم هاتفك');
  String get phoneHint => t('+20 1XX XXX XXXX', '+20 1XX XXX XXXX');
  String get save => t('Save', 'حفظ');
  String get cancelBtn => t('Cancel', 'إلغاء');

  // ---- Trips ----
  String get trips => t('Trips', 'الرحلات');
  String get rating => t('Rating', 'التقييم');
  String get saved => t('Saved', 'الموفقة');
  String get noRequests => t('No requests yet.', 'لا توجد طلبات بعد.');
  String get retry => t('Retry', 'إعادة المحاولة');
  String get request => t('Request', 'طلب');
  String get cancelRequest => t('Cancel', 'إلغاء');
  String get truck => t('Truck', 'العربة');

  // ---- City picker ----
  String get pickCity => t('Pick a city', 'اختر مدينة');
  String get confirmCity => t('Choose', 'اختيار');
}
