/// Comprehensive validation utilities for form inputs
class ValidationUtils {
  // Email validation with proper regex
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Simple password validation (for login, less strict)
  static String? validateSimplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
      String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (cleanPhone.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    // Check if it starts with valid country codes (optional, can be customized)
    if (cleanPhone.length >= 10 && !RegExp(r'^[1-9]').hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!priceRegex.hasMatch(value.trim())) {
      return 'Please enter a valid price (e.g., 123.45)';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 999999.99) {
      return 'Price cannot exceed 999,999.99';
    }

    return null;
  }

  // Stock quantity validation
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock quantity is required';
    }

    final stock = int.tryParse(value.trim());
    if (stock == null) {
      return 'Please enter a valid number';
    }

    if (stock < 0) {
      return 'Stock quantity cannot be negative';
    }

    if (stock > 999999) {
      return 'Stock quantity cannot exceed 999,999';
    }

    return null;
  }

  // SKU validation
  static String? validateSKU(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 3) {
        return 'SKU must be at least 3 characters';
      }

      if (value.trim().length > 20) {
        return 'SKU must be less than 20 characters';
      }

      // Check for valid SKU format (alphanumeric, hyphens, underscores)
      final skuRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
      if (!skuRegex.hasMatch(value.trim())) {
        return 'SKU can only contain letters, numbers, hyphens, and underscores';
      }
    }

    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }

    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }

    if (value.trim().length > 1000) {
      return 'Description must be less than 1000 characters';
    }

    return null;
  }

  // Title/Product name validation
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }

    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters long';
    }

    if (value.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }

    return null;
  }

  // Search query validation and sanitization
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a search term';
    }

    if (value.trim().length < 2) {
      return 'Search term must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Search term must be less than 100 characters';
    }

    // Check for potentially harmful characters
    final harmfulRegex = RegExp(r'[<>]');
    if (harmfulRegex.hasMatch(value)) {
      return 'Search term contains invalid characters';
    }

    return null;
  }

  // Sanitize search query
  static String sanitizeSearchQuery(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[<>]'), '') // Remove potentially harmful chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .substring(0, value.length > 100 ? 100 : value.length);
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters long';
    }

    if (value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }

    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }

    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'City name must be less than 50 characters';
    }

    final cityRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!cityRegex.hasMatch(value.trim())) {
      return 'City name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Postal code validation
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }

    final cleanPostal = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPostal.length < 5) {
      return 'Postal code must be at least 5 digits';
    }

    if (cleanPostal.length > 10) {
      return 'Postal code must be less than 10 digits';
    }

    return null;
  }

  // Credit card number validation (basic)
  static String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }

    final cleanCard = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanCard.length < 13 || cleanCard.length > 19) {
      return 'Please enter a valid card number';
    }

    // Luhn algorithm for basic validation
    if (!_isValidLuhn(cleanCard)) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    final cleanCVV = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanCVV.length < 3 || cleanCVV.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }

    return null;
  }

  // Expiry date validation
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!expiryRegex.hasMatch(value.trim())) {
      return 'Please enter expiry date in MM/YY format';
    }

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');

    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 0); // Last day of the month

    if (expiry.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }

  // Delivery time validation
  static String? validateDeliveryTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Delivery time is required';
    }

    final days = int.tryParse(value.trim());
    if (days == null) {
      return 'Please enter a valid number of days';
    }

    if (days < 1) {
      return 'Delivery time must be at least 1 day';
    }

    if (days > 365) {
      return 'Delivery time cannot exceed 365 days';
    }

    return null;
  }

  // Message validation
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message is required';
    }

    if (value.trim().length < 10) {
      return 'Message must be at least 10 characters long';
    }

    if (value.trim().length > 1000) {
      return 'Message must be less than 1000 characters';
    }

    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value.trim());
    if (quantity == null) {
      return 'Please enter a valid number';
    }

    if (quantity < 1) {
      return 'Quantity must be at least 1';
    }

    if (quantity > 9999) {
      return 'Quantity cannot exceed 9,999';
    }

    return null;
  }

  // Luhn algorithm for credit card validation
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Generic length validation
  static String? validateLength(
      String? value, String fieldName, int minLength, int maxLength) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final urlRegex = RegExp(
        r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
        caseSensitive: false,
      );

      if (!urlRegex.hasMatch(value.trim())) {
        return 'Please enter a valid URL';
      }
    }

    return null;
  }
}
