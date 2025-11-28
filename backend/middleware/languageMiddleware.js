/**
 * Language Middleware
 * Handles language detection and localization for API responses
 */

const supportedLanguages = ['en', 'es', 'hi', 'ne', 'bn', 'ta', 'te', 'ml', 'ur', 'ar'];
const defaultLanguage = 'en';

// Language detection priority:
// 1. Accept-Language header
// 2. Query parameter 'lang'
// 3. Default to English

const detectLanguage = (req) => {
    // Check query parameter first
    if (req.query.lang && supportedLanguages.includes(req.query.lang)) {
        return req.query.lang;
    }

    // Check Accept-Language header
    const acceptLanguage = req.headers['accept-language'];
    if (acceptLanguage) {
        // Parse Accept-Language header (e.g., "en-US,en;q=0.9,hi;q=0.8")
        const languages = acceptLanguage.split(',').map(lang => {
            const [locale] = lang.trim().split(';');
            return locale.split('-')[0]; // Get language code only (ignore country)
        });

        // Find first supported language
        for (const lang of languages) {
            if (supportedLanguages.includes(lang)) {
                return lang;
            }
        }
    }

    return defaultLanguage;
};

// Middleware function
const languageMiddleware = (req, res, next) => {
    const language = detectLanguage(req);

    // Attach language to request object
    req.language = language;

    // Set language in response headers for client reference
    res.setHeader('X-API-Language', language);

    next();
};

// Translation helper function
const getLocalizedMessage = (key, language = defaultLanguage) => {
    const translations = {
        en: {
            // Common messages
            'success': 'Success',
            'error': 'Error',
            'not_found': 'Resource not found',
            'unauthorized': 'Unauthorized access',
            'forbidden': 'Access forbidden',
            'validation_error': 'Validation error',
            'server_error': 'Internal server error',

            // Authentication
            'login_success': 'Login successful',
            'login_failed': 'Login failed',
            'logout_success': 'Logout successful',
            'register_success': 'Registration successful',
            'invalid_credentials': 'Invalid credentials',

            // Products
            'product_created': 'Product created successfully',
            'product_updated': 'Product updated successfully',
            'product_deleted': 'Product deleted successfully',
            'product_not_found': 'Product not found',

            // Orders
            'order_created': 'Order created successfully',
            'order_updated': 'Order updated successfully',
            'order_cancelled': 'Order cancelled successfully',
            'order_not_found': 'Order not found',

            // Cart
            'item_added_to_cart': 'Item added to cart',
            'item_removed_from_cart': 'Item removed from cart',
            'cart_cleared': 'Cart cleared',

            // Categories
            'category_created': 'Category created successfully',
            'category_updated': 'Category updated successfully',
            'category_deleted': 'Category deleted successfully',
        },
        es: {
            'success': 'Éxito',
            'error': 'Error',
            'not_found': 'Recurso no encontrado',
            'unauthorized': 'Acceso no autorizado',
            'forbidden': 'Acceso prohibido',
            'validation_error': 'Error de validación',
            'server_error': 'Error interno del servidor',
            'login_success': 'Inicio de sesión exitoso',
            'login_failed': 'Inicio de sesión fallido',
            'logout_success': 'Cierre de sesión exitoso',
            'register_success': 'Registro exitoso',
            'invalid_credentials': 'Credenciales inválidas',
            'product_created': 'Producto creado exitosamente',
            'product_updated': 'Producto actualizado exitosamente',
            'product_deleted': 'Producto eliminado exitosamente',
            'product_not_found': 'Producto no encontrado',
            'order_created': 'Pedido creado exitosamente',
            'order_updated': 'Pedido actualizado exitosamente',
            'order_cancelled': 'Pedido cancelado exitosamente',
            'order_not_found': 'Pedido no encontrado',
            'item_added_to_cart': 'Artículo agregado al carrito',
            'item_removed_from_cart': 'Artículo eliminado del carrito',
            'cart_cleared': 'Carrito vaciado',
            'category_created': 'Categoría creada exitosamente',
            'category_updated': 'Categoría actualizada exitosamente',
            'category_deleted': 'Categoría eliminada exitosamente',
        },
        hi: {
            'success': 'सफलता',
            'error': 'त्रुटि',
            'not_found': 'संसाधन नहीं मिला',
            'unauthorized': 'अनधिकृत पहुंच',
            'forbidden': 'पहुंच निषिद्ध',
            'validation_error': 'सत्यापन त्रुटि',
            'server_error': 'आंतरिक सर्वर त्रुटि',
            'login_success': 'लॉगिन सफल',
            'login_failed': 'लॉगिन विफल',
            'logout_success': 'लॉगआउट सफल',
            'register_success': 'पंजीकरण सफल',
            'invalid_credentials': 'अमान्य क्रेडेंशियल्स',
            'product_created': 'उत्पाद सफलतापूर्वक बनाया गया',
            'product_updated': 'उत्पाद सफलतापूर्वक अपडेट किया गया',
            'product_deleted': 'उत्पाद सफलतापूर्वक हटाया गया',
            'product_not_found': 'उत्पाद नहीं मिला',
            'order_created': 'आर्डर सफलतापूर्वक बनाया गया',
            'order_updated': 'आर्डर सफलतापूर्वक अपडेट किया गया',
            'order_cancelled': 'आर्डर सफलतापूर्वक रद्द किया गया',
            'order_not_found': 'आर्डर नहीं मिला',
            'item_added_to_cart': 'आइटम कार्ट में जोड़ा गया',
            'item_removed_from_cart': 'आइटम कार्ट से हटाया गया',
            'cart_cleared': 'कार्ट खाली किया गया',
            'category_created': 'श्रेणी सफलतापूर्वक बनाई गई',
            'category_updated': 'श्रेणी सफलतापूर्वक अपडेट की गई',
            'category_deleted': 'श्रेणी सफलतापूर्वक हटाई गई',
        },
        ne: {
            'success': 'सफलता',
            'error': 'त्रुटि',
            'not_found': 'संसाधन भेटिएन',
            'unauthorized': 'अनधिकृत पहुँच',
            'forbidden': 'पहुँच निषेधित',
            'validation_error': 'मान्यकरण त्रुटि',
            'server_error': 'आन्तरिक सर्भर त्रुटि',
            'login_success': 'लगइन सफल',
            'login_failed': 'लगइन असफल',
            'logout_success': 'लगआउट सफल',
            'register_success': 'दर्ता सफल',
            'invalid_credentials': 'अमान्य प्रमाणहरू',
            'product_created': 'उत्पादन सफलतापूर्वक सिर्जना गरियो',
            'product_updated': 'उत्पादन सफलतापूर्वक अपडेट गरियो',
            'product_deleted': 'उत्पादन सफलतापूर्वक हटाइयो',
            'product_not_found': 'उत्पादन भेटिएन',
            'order_created': 'अर्डर सफलतापूर्वक सिर्जना गरियो',
            'order_updated': 'अर्डर सफलतापूर्वक अपडेट गरियो',
            'order_cancelled': 'अर्डर सफलतापूर्वक रद्द गरियो',
            'order_not_found': 'अर्डर भेटिएन',
            'item_added_to_cart': 'आइटम कार्टमा थपियो',
            'item_removed_from_cart': 'आइटम कार्टबाट हटाइयो',
            'cart_cleared': 'कार्ट खाली गरियो',
            'category_created': 'वर्ग सफलतापूर्वक सिर्जना गरियो',
            'category_updated': 'वर्ग सफलतापूर्वक अपडेट गरियो',
            'category_deleted': 'वर्ग सफलतापूर्वक हटाइयो',
        },
        bn: {
            'success': 'সাফল্য',
            'error': 'ত্রুটি',
            'not_found': 'সম্পদ পাওয়া যায়নি',
            'unauthorized': 'অননুমোদিত অ্যাক্সেস',
            'forbidden': 'অ্যাক্সেস নিষিদ্ধ',
            'validation_error': 'বৈধতা ত্রুটি',
            'server_error': 'অভ্যন্তরীণ সার্ভার ত্রুটি',
            'login_success': 'লগইন সফল',
            'login_failed': 'লগইন ব্যর্থ',
            'logout_success': 'লগআউট সফল',
            'register_success': 'নিবন্ধন সফল',
            'invalid_credentials': 'অবৈধ শংসাপত্র',
            'product_created': 'পণ্য সফলভাবে তৈরি করা হয়েছে',
            'product_updated': 'পণ্য সফলভাবে আপডেট করা হয়েছে',
            'product_deleted': 'পণ্য সফলভাবে মুছে ফেলা হয়েছে',
            'product_not_found': 'পণ্য পাওয়া যায়নি',
            'order_created': 'অর্ডার সফলভাবে তৈরি করা হয়েছে',
            'order_updated': 'অর্ডার সফলভাবে আপডেট করা হয়েছে',
            'order_cancelled': 'অর্ডার সফলভাবে বাতিল করা হয়েছে',
            'order_not_found': 'অর্ডার পাওয়া যায়নি',
            'item_added_to_cart': 'আইটেম কার্টে যোগ করা হয়েছে',
            'item_removed_from_cart': 'আইটেম কার্ট থেকে সরানো হয়েছে',
            'cart_cleared': 'কার্ট খালি করা হয়েছে',
            'category_created': 'বিভাগ সফলভাবে তৈরি করা হয়েছে',
            'category_updated': 'বিভাগ সফলভাবে আপডেট করা হয়েছে',
            'category_deleted': 'বিভাগ সফলভাবে মুছে ফেলা হয়েছে',
        },
        ta: {
            'success': 'வெற்றி',
            'error': 'பிழை',
            'not_found': 'வளம் கிடைக்கவில்லை',
            'unauthorized': 'அங்கீகரிக்கப்படாத அணுகல்',
            'forbidden': 'அணுகல் தடைசெய்யப்பட்டது',
            'validation_error': 'சரிபார்ப்பு பிழை',
            'server_error': 'உள் சேவையக பிழை',
            'login_success': 'உள்நுழைவு வெற்றிகரமாக',
            'login_failed': 'உள்நுழைவு தோல்வியடைந்தது',
            'logout_success': 'வெளியேறுதல் வெற்றிகரமாக',
            'register_success': 'பதிவு வெற்றிகரமாக',
            'invalid_credentials': 'தவறான சான்றுகள்',
            'product_created': 'தயாரிப்பு வெற்றிகரமாக உருவாக்கப்பட்டது',
            'product_updated': 'தயாரிப்பு வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
            'product_deleted': 'தயாரிப்பு வெற்றிகரமாக நீக்கப்பட்டது',
            'product_not_found': 'தயாரிப்பு கிடைக்கவில்லை',
            'order_created': 'ஆர்டர் வெற்றிகரமாக உருவாக்கப்பட்டது',
            'order_updated': 'ஆர்டர் வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
            'order_cancelled': 'ஆர்டர் வெற்றிகரமாக ரத்து செய்யப்பட்டது',
            'order_not_found': 'ஆர்டர் கிடைக்கவில்லை',
            'item_added_to_cart': 'பொருள் கார்ட்டில் சேர்க்கப்பட்டது',
            'item_removed_from_cart': 'பொருள் கார்ட்டில் இருந்து அகற்றப்பட்டது',
            'cart_cleared': 'கார்ட் காலி செய்யப்பட்டது',
            'category_created': 'வகை வெற்றிகரமாக உருவாக்கப்பட்டது',
            'category_updated': 'வகை வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
            'category_deleted': 'வகை வெற்றிகரமாக நீக்கப்பட்டது',
        },
        te: {
            'success': 'విజయం',
            'error': 'లోపం',
            'not_found': 'వనరు కనుగొనబడలేదు',
            'unauthorized': 'అనధికార ప్రాప్యత',
            'forbidden': 'ప్రాప్యత నిషేధించబడింది',
            'validation_error': 'ధ్రువీకరణ లోపం',
            'server_error': 'అంతర్గత సర్వర్ లోపం',
            'login_success': 'లాగిన్ విజయవంతం',
            'login_failed': 'లాగిన్ విఫలమైంది',
            'logout_success': 'లాగ్అవుట్ విజయవంతం',
            'register_success': 'నమోదు విజయవంతం',
            'invalid_credentials': 'చెల్లని ఆధారాలు',
            'product_created': 'ఉత్పత్తి విజయవంతంగా సృష్టించబడింది',
            'product_updated': 'ఉత్పత్తి విజయవంతంగా అప్డేట్ చేయబడింది',
            'product_deleted': 'ఉత్పత్తి విజయవంతంగా తొలగించబడింది',
            'product_not_found': 'ఉత్పత్తి కనుగొనబడలేదు',
            'order_created': 'ఆర్డర్ విజయవంతంగా సృష్టించబడింది',
            'order_updated': 'ఆర్డర్ విజయవంతంగా అప్డేట్ చేయబడింది',
            'order_cancelled': 'ఆర్డర్ విజయవంతంగా రద్దు చేయబడింది',
            'order_not_found': 'ఆర్డర్ కనుగొనబడలేదు',
            'item_added_to_cart': 'వస్తువు కార్ట్కు జోడించబడింది',
            'item_removed_from_cart': 'వస్తువు కార్ట్ నుండి తీసివేయబడింది',
            'cart_cleared': 'కార్ట్ క్లియర్ చేయబడింది',
            'category_created': 'వర్గం విజయవంతంగా సృష్టించబడింది',
            'category_updated': 'వర్గం విజయవంతంగా అప్డేట్ చేయబడింది',
            'category_deleted': 'వర్గం విజయవంతంగా తొలగించబడింది',
        },
        ml: {
            'success': 'വിജയം',
            'error': 'പിശക്',
            'not_found': 'വിഭവം കണ്ടെത്തിയില്ല',
            'unauthorized': 'അനധികൃത പ്രവേശനം',
            'forbidden': 'പ്രവേശനം നിരോധിച്ചിരിക്കുന്നു',
            'validation_error': 'സാധൂകരണ പിശക്',
            'server_error': 'ആന്തരിക സെർവർ പിശക്',
            'login_success': 'ലോഗിൻ വിജയകരം',
            'login_failed': 'ലോഗിൻ പരാജയപ്പെട്ടു',
            'logout_success': 'ലോഗ്ഔട്ട് വിജയകരം',
            'register_success': 'രജിസ്ട്രേഷൻ വിജയകരം',
            'invalid_credentials': 'അസാധുവായ ക്രെഡൻഷ്യലുകൾ',
            'product_created': 'ഉൽപ്പന്നം വിജയകരമായി സൃഷ്ടിച്ചു',
            'product_updated': 'ഉൽപ്പന്നം വിജയകരമായി അപ്ഡേറ്റ് ചെയ്തു',
            'product_deleted': 'ഉൽപ്പന്നം വിജയകരമായി ഇല്ലാതാക്കി',
            'product_not_found': 'ഉൽപ്പന്നം കണ്ടെത്തിയില്ല',
            'order_created': 'ഓർഡർ വിജയകരമായി സൃഷ്ടിച്ചു',
            'order_updated': 'ഓർഡർ വിജയകരമായി അപ്ഡേറ്റ് ചെയ്തു',
            'order_cancelled': 'ഓർഡർ വിജയകരമായി റദ്ദാക്കി',
            'order_not_found': 'ഓർഡർ കണ്ടെത്തിയില്ല',
            'item_added_to_cart': 'ഇനം കാർട്ടിലേക്ക് ചേർത്തു',
            'item_removed_from_cart': 'ഇനം കാർട്ടിൽ നിന്നും നീക്കം ചെയ്തു',
            'cart_cleared': 'കാർട്ട് വൃത്തിയാക്കി',
            'category_created': 'വിഭാഗം വിജയകരമായി സൃഷ്ടിച്ചു',
            'category_updated': 'വിഭാഗം വിജയകരമായി അപ്ഡേറ്റ് ചെയ്തു',
            'category_deleted': 'വിഭാഗം വിജയകരമായി ഇല്ലാതാക്കി',
        },
        ur: {
            'success': 'کامیابی',
            'error': 'خرابی',
            'not_found': 'وسیلہ نہیں ملا',
            'unauthorized': 'غیر مجاز رسائی',
            'forbidden': 'رسائی ممنوع',
            'validation_error': 'توثیق کی خرابی',
            'server_error': 'اندرونی سرور کی خرابی',
            'login_success': 'لاگ ان کامیاب',
            'login_failed': 'لاگ ان ناکام',
            'logout_success': 'لاگ آؤٹ کامیاب',
            'register_success': 'رجسٹریشن کامیاب',
            'invalid_credentials': 'غلط اسناد',
            'product_created': 'پروڈکٹ کامیابی سے بنایا گیا',
            'product_updated': 'پروڈکٹ کامیابی سے اپ ڈیٹ کیا گیا',
            'product_deleted': 'پروڈکٹ کامیابی سے حذف کیا گیا',
            'product_not_found': 'پروڈکٹ نہیں ملا',
            'order_created': 'آرڈر کامیابی سے بنایا گیا',
            'order_updated': 'آرڈر کامیابی سے اپ ڈیٹ کیا گیا',
            'order_cancelled': 'آرڈر کامیابی سے منسوخ کیا گیا',
            'order_not_found': 'آرڈر نہیں ملا',
            'item_added_to_cart': 'آئٹم کارٹ میں شامل کیا گیا',
            'item_removed_from_cart': 'آئٹم کارٹ سے ہٹایا گیا',
            'cart_cleared': 'کارٹ صاف کیا گیا',
            'category_created': 'کیٹگری کامیابی سے بنائی گئی',
            'category_updated': 'کیٹگری کامیابی سے اپ ڈیٹ کی گئی',
            'category_deleted': 'کیٹگری کامیابی سے حذف کی گئی',
        },
        ar: {
            'success': 'نجح',
            'error': 'خطأ',
            'not_found': 'الموارد غير موجودة',
            'unauthorized': 'وصول غير مصرح به',
            'forbidden': 'الوصول محظور',
            'validation_error': 'خطأ في التحقق',
            'server_error': 'خطأ في الخادم الداخلي',
            'login_success': 'تم تسجيل الدخول بنجاح',
            'login_failed': 'فشل في تسجيل الدخول',
            'logout_success': 'تم تسجيل الخروج بنجاح',
            'register_success': 'تم التسجيل بنجاح',
            'invalid_credentials': 'بيانات اعتماد غير صحيحة',
            'product_created': 'تم إنشاء المنتج بنجاح',
            'product_updated': 'تم تحديث المنتج بنجاح',
            'product_deleted': 'تم حذف المنتج بنجاح',
            'product_not_found': 'المنتج غير موجود',
            'order_created': 'تم إنشاء الطلب بنجاح',
            'order_updated': 'تم تحديث الطلب بنجاح',
            'order_cancelled': 'تم إلغاء الطلب بنجاح',
            'order_not_found': 'الطلب غير موجود',
            'item_added_to_cart': 'تمت إضافة العنصر إلى السلة',
            'item_removed_from_cart': 'تم إزالة العنصر من السلة',
            'cart_cleared': 'تم مسح السلة',
            'category_created': 'تم إنشاء الفئة بنجاح',
            'category_updated': 'تم تحديث الفئة بنجاح',
            'category_deleted': 'تم حذف الفئة بنجاح',
        }
    };

    return translations[language]?.[key] || translations[defaultLanguage]?.[key] || key;
};

module.exports = {
    languageMiddleware,
    getLocalizedMessage,
    supportedLanguages,
    defaultLanguage
};