import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'state.dart';

const _s = <String, Map<String, String>>{
  // App & Branding
  'app': {'en': 'MilkDirect', 'hi': 'मिल्कडायरेक्ट', 'mr': 'मिल्कडायरेक्ट'},
  'tagline': {
    'en': 'Farm Fresh. Fair Price. Daily at Your Door.',
    'hi': 'खेत से ताज़ा, उचित दाम, रोज़ आपके द्वार',
    'mr': 'शेतातून ताजे, योग्य दर, रोज तुमच्या दारी',
  },
  'welcome': {'en': 'Welcome to MilkDirect', 'hi': 'मिल्कडायरेक्ट में आपका स्वागत है', 'mr': 'मिल्कडायरेक्ट मध्ये आपले स्वागत आहे'},

  // Role Selection Screen
  'role_select_title': {'en': 'Welcome to MilkDirect', 'hi': 'मिल्कडायरेक्ट में स्वागत है', 'mr': 'मिल्कडायरेक्ट मध्ये स्वागत आहे'},
  'role_select_sub': {'en': 'Please select how you want to continue', 'hi': 'आगे बढ़ने के लिए अपना विकल्प चुनें', 'mr': 'पुढे जाण्यासाठी तुमचा पर्याय निवडा'},
  'i_am_customer_card': {'en': 'I am a Customer', 'hi': 'मैं एक ग्राहक हूँ', 'mr': 'मी एक ग्राहक आहे'},
  'customer_card_desc': {'en': 'Get fresh farm milk delivered daily to your doorstep', 'hi': 'घर बैठे रोज़ ताज़ा शुद्ध दूध प्राप्त करें', 'mr': 'घरी बसल्या रोज ताजे शुद्ध दूध मिळवा'},
  'i_am_supplier_card': {'en': 'I am a Farmer / Milkman', 'hi': 'मैं किसान / दूधवाला हूँ', 'mr': 'मी शेतकरी / दूधवाला आहे'},
  'supplier_card_desc': {'en': 'Sell fresh milk directly to nearby customers & manage routes', 'hi': 'नजदीकी ग्राहकों को सीधे दूध बेचें और डिलीवरी प्रबंधित करें', 'mr': 'जवळच्या ग्राहकांना थेट दूध विका आणि डिलिव्हरी सांभाळा'},
  'admin_login_link': {'en': 'Administrator Login →', 'hi': 'एडमिनिस्ट्रेटर लॉगिन →', 'mr': 'प्रशासक (Admin) लॉगिन →'},
  'change_role': {'en': 'Change role', 'hi': 'भूमिका बदलें', 'mr': 'भूमिका बदला'},

  // Customer Login & Setup
  'customer_login_title': {'en': 'Customer Sign In', 'hi': 'ग्राहक साइन इन', 'mr': 'ग्राहक साइन इन'},
  'customer_login_sub': {'en': 'Enter your email address to receive a 6-digit OTP', 'hi': '6 अंकों का OTP प्राप्त करने के लिए ईमेल पता दर्ज करें', 'mr': '6 अंकी OTP मिळवण्यासाठी ईमेल पत्ता टाका'},
  'email_address': {'en': 'Email Address', 'hi': 'ईमेल पता', 'mr': 'ईमेल पत्ता'},
  'email_hint': {'en': 'name@example.com', 'hi': 'name@example.com', 'mr': 'name@example.com'},
  'phone_number': {'en': 'Mobile Number', 'hi': 'मोबाइल नंबर', 'mr': 'मोबाईल नंबर'},
  'phone_hint': {'en': '9876543210', 'hi': '9876543210', 'mr': '9876543210'},
  'send_otp': {'en': 'Send OTP', 'hi': 'OTP भेजें', 'mr': 'OTP पाठवा'},
  'enter_otp': {'en': 'Enter the 6-digit OTP', 'hi': '6 अंकों का OTP डालें', 'mr': '6 अंकी OTP टाका'},
  'resend_otp': {'en': 'Resend OTP', 'hi': 'फिर से OTP भेजें', 'mr': 'पुन्हा OTP पाठवा'},
  'verify_btn': {'en': 'Verify & Continue', 'hi': 'सत्यापित करें और आगे बढ़ें', 'mr': 'पडताळा आणि पुढे जा'},
  'customer_setup_title': {'en': 'Complete Customer Profile', 'hi': 'ग्राहक प्रोफ़ाइल पूरी करें', 'mr': 'ग्राहक प्रोफाइल पूर्ण करा'},
  'customer_setup_sub': {'en': 'Set up your delivery location for daily milk drops', 'hi': 'दैनिक दूध डिलीवरी के लिए अपना पता सेट करें', 'mr': 'रोजच्या दूध डिलिव्हरीसाठी तुमचा पत्ता सेट करा'},

  // Supplier Login & Registration Wizard
  'supplier_login_title': {'en': 'Supplier Sign In', 'hi': 'सप्लायर साइन इन', 'mr': 'पुरवठादार साइन इन'},
  'supplier_login_sub': {'en': 'Enter your email address to access the supplier portal', 'hi': 'सप्लायर पोर्टल के लिए ईमेल पता दर्ज करें', 'mr': 'पुरवठादार पोर्टलसाठी ईमेल पत्ता टाका'},
  'supplier_wizard_title': {'en': 'Supplier Registration', 'hi': 'सप्लायर पंजीकरण', 'mr': 'पुरवठादार नोंदणी'},
  'step_1_title': {'en': '1. Supplier Type', 'hi': '1. सप्लायर का प्रकार', 'mr': '1. पुरवठादाराचा प्रकार'},
  'step_2_title': {'en': '2. Farm & Personal Info', 'hi': '2. फार्म और व्यक्तिगत जानकारी', 'mr': '2. गोठा आणि वैयक्तिक माहिती'},
  'step_3_title': {'en': '3. Service Areas & UPI', 'hi': '3. सेवा क्षेत्र और UPI', 'mr': '3. सेवा परिसर आणि UPI'},
  'step_4_title': {'en': '4. Verification Documents', 'hi': '4. सत्यापन दस्तावेज़', 'mr': '4. पडताळणी कागदपत्रे'},
  'supplier_type_farmer': {'en': 'Dairy Farmer (Own Cattle)', 'hi': 'डेयरी किसान (खुद के मवेशी)', 'mr': 'डेअरी शेतकरी (स्वतःची जनावरे)'},
  'supplier_type_milkman': {'en': 'Milkman (Collects from Village)', 'hi': 'दूधवाला (गाँव से संकलित)', 'mr': 'दूधवाला (गावातून संकलित)'},
  'shop_farm_name': {'en': 'Dairy Farm / Business Name', 'hi': 'डेयरी फार्म / दुकान का नाम', 'mr': 'डेअरी फार्म / दुकानाचे नाव'},
  'service_pincodes': {'en': 'Service PIN codes (comma separated)', 'hi': 'सेवा पिन कोड (कॉमा से अलग करें)', 'mr': 'सेवा पिन कोड (स्वल्पविरामाने वेगळे करा)'},
  'service_pincodes_hint': {'en': 'e.g. 411001, 411002, 411038', 'hi': 'उदा. 411001, 411002, 411038', 'mr': 'उदा. 411001, 411002, 411038'},
  'fssai_doc_hint': {'en': 'FSSAI License / Cattle ownership doc (Optional at signup)', 'hi': 'FSSAI लाइसेंस या मवेशी दस्तावेज (वैकल्पिक)', 'mr': 'FSSAI परवाना किंवा जनावरांचे प्रमाणपत्र (ऐच्छिक)'},

  // Verification Pending Screen
  'verif_pending_title': {'en': 'Account Under Review', 'hi': 'खाता समीक्षाधीन है', 'mr': 'खाते पुनरावलोकनाधीन आहे'},
  'verif_pending_desc': {'en': 'Our team is reviewing your farm documents. You can set up your milk listings now, but customers will see you after approval.', 'hi': 'हमारी टीम आपके दस्तावेजों की समीक्षा कर रही है। आप अभी दूध लिस्टिंग बना सकते हैं, मंज़ूरी के बाद ग्राहक देख सकेंगे।', 'mr': 'आमची टीम कागदपत्रांची पडताळणी करत आहे. तुम्ही आता दूध यादी तयार करू शकता, मंजुरीनंतर ग्राहक पाहू शकतील.'},
  'verif_step_submitted': {'en': 'Application Submitted', 'hi': 'आवेदन जमा किया गया', 'mr': 'अर्ज सादर केला'},
  'verif_step_review': {'en': 'Under Review by Admin', 'hi': 'एडमिन द्वारा समीक्षा जारी', 'mr': 'अॅडमिनद्वारे पडताळणी सुरू'},
  'verif_step_verified': {'en': 'Verified & Live', 'hi': 'सत्यापित और सक्रिय', 'mr': 'पडताळणी पूर्ण व लाइव्ह'},
  'verif_step_rejected': {'en': 'Application Rejected', 'hi': 'आवेदन अस्वीकृत', 'mr': 'अर्ज नाकारला'},
  'goto_dashboard': {'en': 'Open Supplier Dashboard', 'hi': 'सप्लायर डैशबोर्ड खोलें', 'mr': 'पुरवठादार डॅशबोर्ड उघडा'},

  // Admin Login Screen
  'admin_login_title': {'en': 'Administrator Access', 'hi': 'एडमिनिस्ट्रेटर लॉगिन', 'mr': 'प्रशासक लॉगिन'},
  'admin_login_sub': {'en': 'Authorized personnel only. Email & Password credentials required.', 'hi': 'केवल अधिकृत स्टाफ के लिए। ईमेल और पासवर्ड आवश्यक है।', 'mr': 'फक्त अधिकृत कर्मचाऱ्यांसाठी. ईमेल आणि पासवर्ड आवश्यक आहे.'},
  'admin_email': {'en': 'Admin Email', 'hi': 'एडमिन ईमेल', 'mr': 'अॅडमिन ईमेल'},
  'admin_password': {'en': 'Password', 'hi': 'पासवर्ड', 'mr': 'पासवर्ड'},
  'admin_login_btn': {'en': 'Sign In as Admin', 'hi': 'एडमिन के रूप में साइन इन करें', 'mr': 'अॅडमिन म्हणून साइन इन करा'},
  'forgot_password': {'en': 'Forgot Password?', 'hi': 'पासवर्ड भूल गए?', 'mr': 'पासवर्ड विसरलात?'},
  'pwd_reset_sent': {'en': 'Password reset link sent to your email', 'hi': 'पासवर्ड रीसेट लिंक आपके ईमेल पर भेज दी गई है', 'mr': 'पासवर्ड रीसेट लिंक तुमच्या ईमेलवर पाठवली आहे'},
  'admin_security_note': {'en': 'Admin accounts can only be provisioned directly via Supabase database console.', 'hi': 'एडमिन खाते केवल डेटाबेस से ही बनाए जा सकते हैं।', 'mr': 'अॅडमिन खाती केवळ डेटाबेसमधूनच तयार केली जाऊ शकतात.'},

  // Role Enforcement Errors
  'role_err_supplier_to_customer': {
    'en': 'This email is registered as a Supplier. Please use the Farmer / Milkman Login.',
    'hi': 'यह ईमेल सप्लायर के रूप में पंजीकृत है। कृपया किसान / दूधवाला लॉगिन का उपयोग करें।',
    'mr': 'हा ईमेल पुरवठादार म्हणून नोंदणीकृत आहे. कृपया शेतकरी / दूधवाला लॉगिन वापरा.',
  },
  'role_err_customer_to_supplier': {
    'en': 'This email is registered as a Customer. Please use the Customer Login.',
    'hi': 'यह ईमेल ग्राहक के रूप में पंजीकृत है। कृपया ग्राहक लॉगिन का उपयोग करें।',
    'mr': 'हा ईमेल ग्राहक म्हणून नोंदणीकृत आहे. कृपया ग्राहक लॉगिन वापरा.',
  },
  'role_err_not_admin': {
    'en': 'Access Denied: This account does not have administrator privileges.',
    'hi': 'पहुंच अस्वीकृत: इस खाते के पास एडमिन अधिकार नहीं हैं।',
    'mr': 'प्रवेश नाकारला: या खात्याला प्रशासक अधिकार नाहीत.',
  },
  'acc_blocked': {
    'en': 'Your account has been blocked. Please contact support.',
    'hi': 'आपका खाता ब्लॉक कर दिया गया है। कृपया सहायता से संपर्क करें।',
    'mr': 'तुमचे खाते ब्लॉक केले गेले आहे. कृपया समर्थनाशी संपर्क साधा.',
  },

  // Common UI Elements
  'name': {'en': 'Full name', 'hi': 'पूरा नाम', 'mr': 'पूर्ण नाव'},
  'village': {'en': 'Village / Locality', 'hi': 'गाँव / इलाका', 'mr': 'गाव / परिसर'},
  'pincode': {'en': 'PIN code', 'hi': 'पिन कोड', 'mr': 'पिन कोड'},
  'upi': {'en': 'UPI ID (for payments)', 'hi': 'UPI ID (भुगतान के लिए)', 'mr': 'UPI ID (पेमेंटसाठी)'},
  'address': {'en': 'Delivery address', 'hi': 'डिलीवरी पता', 'mr': 'वितरण पत्ता'},
  'landmark': {'en': 'Landmark (Optional)', 'hi': 'लैंडमार्क (पहचान)', 'mr': 'लँडमार्क (जवळची खूण)'},
  'contact_phone': {'en': 'Contact phone (optional)', 'hi': 'संपर्क नंबर (वैकल्पिक)', 'mr': 'संपर्क नंबर (ऐच्छिक)'},
  'continue': {'en': 'Continue', 'hi': 'आगे बढ़ें', 'mr': 'पुढे जा'},
  'back': {'en': 'Back', 'hi': 'पीछे', 'mr': 'मागे'},
  'save': {'en': 'Save Details', 'hi': 'सहेजें', 'mr': 'जतन करा'},
  'cancel': {'en': 'Cancel', 'hi': 'रद्द करें', 'mr': 'रद्द करा'},
  'fill_all': {'en': 'Please fill all required fields', 'hi': 'सभी आवश्यक जानकारी भरें', 'mr': 'सर्व आवश्यक माहिती भरा'},
  'sign_out': {'en': 'Sign Out', 'hi': 'साइन आउट', 'mr': 'साइन आउट'},
  'verified': {'en': 'Documents Verified', 'hi': 'दस्तावेज़ सत्यापित', 'mr': 'कागदपत्रे पडताळलेली'},
  'suppliers': {'en': 'Suppliers', 'hi': 'आपूर्तिकर्ता', 'mr': 'पुरवठादार'},
  'my_milk': {'en': 'My Milk', 'hi': 'मेरा दूध', 'mr': 'माझे दूध'},
  'orders': {'en': 'Orders', 'hi': 'ऑर्डर', 'mr': 'ऑर्डर'},
  'profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल', 'mr': 'प्रोफाइल'},
  'billing': {'en': 'Billing', 'hi': 'बिलिंग', 'mr': 'बिलिंग'},
  'today': {'en': 'Today', 'hi': 'आज', 'mr': 'आज'},
  'cow': {'en': 'Cow Milk', 'hi': 'गाय का दूध', 'mr': 'गायीचे दूध'},
  'buffalo': {'en': 'Buffalo Milk', 'hi': 'भैंस का दूध', 'mr': 'म्हशीचे दूध'},
  'other': {'en': 'Other Milk', 'hi': 'अन्य दूध', 'mr': 'इतर दूध'},
  'farmer': {'en': 'Farmer', 'hi': 'किसान', 'mr': 'शेतकरी'},
  'milkman': {'en': 'Milkman', 'hi': 'दूधवाला', 'mr': 'दूधवाला'},
  'customer': {'en': 'Customer', 'hi': 'ग्राहक', 'mr': 'ग्राहक'},
  'admin': {'en': 'Admin', 'hi': 'एडमिन', 'mr': 'अॅडमिन'},
  'admin_dashboard': {'en': 'Admin Dashboard', 'hi': 'एडमिन डैशबोर्ड', 'mr': 'अॅडमिन डॅशबोर्ड'},
  'verify_suppliers': {'en': 'Supplier Verification', 'hi': 'सत्यापन', 'mr': 'पडताळणी'},
  'complaints': {'en': 'Complaints & Support', 'hi': 'शिकायतें', 'mr': 'तक्रारी'},
  'user_management': {'en': 'Users', 'hi': 'उपयोगकर्ता', 'mr': 'वापरकर्ते'},
  'approve': {'en': 'Approve & Verify', 'hi': 'मंज़ूर करें', 'mr': 'मंजूर करा'},
  'reject': {'en': 'Reject', 'hi': 'अस्वीकार करें', 'mr': 'नाकारा'},
  'resolve': {'en': 'Mark as Resolved', 'hi': 'हल किया गया', 'mr': 'निकाली काढा'},
  'total_customers': {'en': 'Total Customers', 'hi': 'कुल ग्राहक', 'mr': 'एकूण ग्राहक'},
  'total_suppliers': {'en': 'Total Suppliers', 'hi': 'कुल आपूर्तिकर्ता', 'mr': 'एकूण पुरवठादार'},
  'active_subs': {'en': 'Active Subscriptions', 'hi': 'सक्रिय सब्सक्रिप्शन', 'mr': 'सक्रिय सबस्क्रिप्शन'},
  'open_complaints': {'en': 'Open Complaints', 'hi': 'खुली शिकायतें', 'mr': 'खुली तक्रारी'},
  'st_active': {'en': 'Active', 'hi': 'चालू', 'mr': 'सुरू'},
  'st_paused': {'en': 'Paused', 'hi': 'रुका हुआ', 'mr': 'थांबलेले'},
  'st_cancelled': {'en': 'Cancelled', 'hi': 'रद्द', 'mr': 'रद्द'},
  'st_pending': {'en': 'Pending', 'hi': 'बाकी', 'mr': 'बाकी'},
  'st_delivered': {'en': 'Delivered', 'hi': 'पहुँचा दिया', 'mr': 'पोहोचवले'},
  'st_missed': {'en': 'Missed', 'hi': 'छूट गया', 'mr': 'चुकले'},
  'st_rescheduled': {'en': 'Rescheduled', 'hi': 'नई तारीख', 'mr': 'नवीन वेळ'},
  'st_paid': {'en': 'Paid', 'hi': 'भुगतान हुआ', 'mr': 'पैसे मिळाले'},
  'st_open': {'en': 'Open', 'hi': 'खुला', 'mr': 'खुली'},
  'st_resolved': {'en': 'Resolved', 'hi': 'हल हुआ', 'mr': 'सोडवली'},
};

String t(BuildContext c, String key) => _lookup(c.watch<AppState>().lang, key);
String tn(BuildContext c, String key) => _lookup(c.read<AppState>().lang, key);
String _lookup(String lang, String key) => _s[key]?[lang] ?? _s[key]?['en'] ?? key;
