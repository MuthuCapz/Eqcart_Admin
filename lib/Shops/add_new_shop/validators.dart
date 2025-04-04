class Validators {
  static String? validateShopName(String? value) {
    if (value == null || value.isEmpty) {
      return "Shop name is required";
    }
    if (value.length > 40) {
      return "Max 40 characters allowed";
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!regex.hasMatch(value)) {
      return "Enter a valid Gmail address (e.g., abc@gmail.com)";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6 || value.length > 12) {
      return "Password must be 6-12 characters";
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return "Description is required";
    }
    if (value.length > 200) {
      return "Max 200 characters allowed";
    }
    return null;
  }

  static String? validateType(String? value) {
    if (value == null || value.isEmpty) {
      return "Type is required";
    }
    if (value.length > 30) {
      return "Max 30 characters allowed";
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number is required";
    }
    final regex = RegExp(r'^\d{10}$');
    if (!regex.hasMatch(value)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  static String? validateContactName(String? value) {
    if (value != null && value.isNotEmpty && value.length > 30) {
      return "Max 30 characters allowed";
    }
    return null;
  }

  static String? validateContactEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
      if (!regex.hasMatch(value)) {
        return "Enter a valid Gmail address";
      }
    }
    return null;
  }
}
