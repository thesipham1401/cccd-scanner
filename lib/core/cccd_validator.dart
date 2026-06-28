final _twelveDigits = RegExp(r'^\d{12}$');

bool isValidCccdNumber(String s) => _twelveDigits.hasMatch(s);
