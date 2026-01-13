import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Flux'**
  String get appTitle;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Servers tab
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// Subscription tab
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Connect button
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Disconnect button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Disconnected status
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// Select server prompt
  ///
  /// In en, this message translates to:
  /// **'Select a server'**
  String get selectServer;

  /// No servers message
  ///
  /// In en, this message translates to:
  /// **'No servers available'**
  String get noServers;

  /// Update subscription button
  ///
  /// In en, this message translates to:
  /// **'Update Subscription'**
  String get updateSubscription;

  /// Add subscription button
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscription;

  /// Subscription URL field
  ///
  /// In en, this message translates to:
  /// **'Subscription URL'**
  String get subscriptionUrl;

  /// Subscription URL placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter subscription URL'**
  String get enterSubscriptionUrl;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode setting
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// System theme mode
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Has account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccount;

  /// Invite section
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// Invite code field
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// Copy success message
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copySuccess;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// Traffic label
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// Upload label
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Download label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Expire date label
  ///
  /// In en, this message translates to:
  /// **'Expire Date'**
  String get expireDate;

  /// Plan label
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// Remaining traffic label
  ///
  /// In en, this message translates to:
  /// **'Remaining Traffic'**
  String get remainingTraffic;

  /// Used traffic label
  ///
  /// In en, this message translates to:
  /// **'Used Traffic'**
  String get usedTraffic;

  /// Total traffic label
  ///
  /// In en, this message translates to:
  /// **'Total Traffic'**
  String get totalTraffic;

  /// Announcement title
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// Maintenance title
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// New version title
  ///
  /// In en, this message translates to:
  /// **'New Version Available'**
  String get newVersion;

  /// Update now button
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// Later button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Force update message
  ///
  /// In en, this message translates to:
  /// **'This update is required'**
  String get forceUpdate;

  /// Telegram label
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// Website label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Support label
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Customer service label
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// Copy link button
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// All nodes label
  ///
  /// In en, this message translates to:
  /// **'All Nodes'**
  String get allNodes;

  /// Recommended label
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Latency label
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latency;

  /// Test latency button
  ///
  /// In en, this message translates to:
  /// **'Test Latency'**
  String get testLatency;

  /// Protocol label
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// Port label
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @monthPrice.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthPrice;

  /// No description provided for @quarterPrice.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterPrice;

  /// No description provided for @halfYearPrice.
  ///
  /// In en, this message translates to:
  /// **'Half Yearly'**
  String get halfYearPrice;

  /// No description provided for @yearPrice.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearPrice;

  /// No description provided for @twoYearPrice.
  ///
  /// In en, this message translates to:
  /// **'2 Years'**
  String get twoYearPrice;

  /// No description provided for @threeYearPrice.
  ///
  /// In en, this message translates to:
  /// **'3 Years'**
  String get threeYearPrice;

  /// No description provided for @onetimePrice.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get onetimePrice;

  /// No description provided for @resetPrice.
  ///
  /// In en, this message translates to:
  /// **'Reset Traffic'**
  String get resetPrice;

  /// No description provided for @selectPlanFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a plan first'**
  String get selectPlanFirst;

  /// No description provided for @orderCreationFail.
  ///
  /// In en, this message translates to:
  /// **'Order creation failed'**
  String get orderCreationFail;

  /// No description provided for @continuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue Payment'**
  String get continuePayment;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @orderAndPay.
  ///
  /// In en, this message translates to:
  /// **'Order & Payment'**
  String get orderAndPay;

  /// No description provided for @payMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payMethod;

  /// No description provided for @selectPlanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a plan first'**
  String get selectPlanPrompt;

  /// No description provided for @goSelect.
  ///
  /// In en, this message translates to:
  /// **'Go Select'**
  String get goSelect;

  /// No description provided for @noPlanSelected.
  ///
  /// In en, this message translates to:
  /// **'No Plan Selected'**
  String get noPlanSelected;

  /// No description provided for @subscriptionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Subscription Period'**
  String get subscriptionPeriod;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon (Optional)'**
  String get coupon;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @orderSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order Successful!'**
  String get orderSuccess;

  /// No description provided for @confirmPaymentResult.
  ///
  /// In en, this message translates to:
  /// **'Checking payment result...'**
  String get confirmPaymentResult;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @productInfo.
  ///
  /// In en, this message translates to:
  /// **'Product Info'**
  String get productInfo;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'Start Using'**
  String get startUsing;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated;

  /// No description provided for @yourSubscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been activated'**
  String get yourSubscriptionActivated;

  /// No description provided for @secureEncryption.
  ///
  /// In en, this message translates to:
  /// **'Secure Encryption'**
  String get secureEncryption;

  /// No description provided for @fastConnection.
  ///
  /// In en, this message translates to:
  /// **'Fast Connection'**
  String get fastConnection;

  /// No description provided for @privacyProtection.
  ///
  /// In en, this message translates to:
  /// **'Privacy Protection'**
  String get privacyProtection;

  /// No description provided for @globalNodes.
  ///
  /// In en, this message translates to:
  /// **'Global Nodes'**
  String get globalNodes;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @unpaidOrder.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Order'**
  String get unpaidOrder;

  /// No description provided for @unpaidOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an unpaid order. Please continue or cancel.'**
  String get unpaidOrderMessage;

  /// No description provided for @cancelingOrder.
  ///
  /// In en, this message translates to:
  /// **'Canceling order...'**
  String get cancelingOrder;

  /// No description provided for @orderCanceled.
  ///
  /// In en, this message translates to:
  /// **'Order canceled, please buy again'**
  String get orderCanceled;

  /// No description provided for @submittingOrder.
  ///
  /// In en, this message translates to:
  /// **'Submitting order...'**
  String get submittingOrder;

  /// No description provided for @cannotOpenPaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot open payment link'**
  String get cannotOpenPaymentLink;

  /// No description provided for @paymentRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment request failed'**
  String get paymentRequestFailed;

  /// No description provided for @paymentException.
  ///
  /// In en, this message translates to:
  /// **'Payment exception'**
  String get paymentException;

  /// No description provided for @paymentResultTimeout.
  ///
  /// In en, this message translates to:
  /// **'Payment timeout, check history later'**
  String get paymentResultTimeout;

  /// No description provided for @queryStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Status query failed'**
  String get queryStatusFailed;

  /// No description provided for @selectNode.
  ///
  /// In en, this message translates to:
  /// **'Select Node'**
  String get selectNode;

  /// No description provided for @nodesAvailable.
  ///
  /// In en, this message translates to:
  /// **'nodes available'**
  String get nodesAvailable;

  /// No description provided for @untested.
  ///
  /// In en, this message translates to:
  /// **'Untested'**
  String get untested;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// No description provided for @clickToConnect.
  ///
  /// In en, this message translates to:
  /// **'Click to Connect'**
  String get clickToConnect;

  /// No description provided for @nodeList.
  ///
  /// In en, this message translates to:
  /// **'Node List'**
  String get nodeList;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @unknownPlan.
  ///
  /// In en, this message translates to:
  /// **'Unknown Plan'**
  String get unknownPlan;

  /// No description provided for @noSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Subscription'**
  String get noSubscription;

  /// No description provided for @trafficResetInfo.
  ///
  /// In en, this message translates to:
  /// **'Traffic resets on day'**
  String get trafficResetInfo;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @secureNetworkConnection.
  ///
  /// In en, this message translates to:
  /// **'Secure Network Connection'**
  String get secureNetworkConnection;

  /// No description provided for @aboutFluxDesc.
  ///
  /// In en, this message translates to:
  /// **'Flux is a secure, fast network acceleration service.'**
  String get aboutFluxDesc;

  /// No description provided for @ixpAccess.
  ///
  /// In en, this message translates to:
  /// **'IXP Access'**
  String get ixpAccess;

  /// No description provided for @ixpAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'High-speed traffic optimization'**
  String get ixpAccessDesc;

  /// No description provided for @fastStable.
  ///
  /// In en, this message translates to:
  /// **'Fast & Stable'**
  String get fastStable;

  /// No description provided for @fastStableDesc.
  ///
  /// In en, this message translates to:
  /// **'Global high-speed dedicated lines'**
  String get fastStableDesc;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No Logs'**
  String get noLogs;

  /// No description provided for @noLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Strict privacy protection'**
  String get noLogsDesc;

  /// No description provided for @strongEncryptionDesc.
  ///
  /// In en, this message translates to:
  /// **'AES-256 bit encryption'**
  String get strongEncryptionDesc;

  /// No description provided for @tokenExpiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Login session expired, please login again'**
  String get tokenExpiredMsg;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @recaptchaOptional.
  ///
  /// In en, this message translates to:
  /// **'Recaptcha (Optional)'**
  String get recaptchaOptional;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/Month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/Year'**
  String get perYear;

  /// No description provided for @networkErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Network error, please try again later'**
  String get networkErrorRetry;

  /// No description provided for @noOrderId.
  ///
  /// In en, this message translates to:
  /// **'No order ID returned'**
  String get noOrderId;

  /// No description provided for @globalNodesAccess.
  ///
  /// In en, this message translates to:
  /// **'Global premium node access'**
  String get globalNodesAccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
