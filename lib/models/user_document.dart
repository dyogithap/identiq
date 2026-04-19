enum DocumentStatus {
  normal,
  expiringSoon,
  expired,
}

class UserDocument {
  final String id;
  final String name;
  final String documentType;
  final DateTime expiryDate;
  final String extractedText;
  final double confidenceScore;

  UserDocument({
    required this.id,
    required this.name,
    required this.documentType,
    required this.expiryDate,
    required this.extractedText,
    required this.confidenceScore,
  });

  /// Normalize date (removes time component)
  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Checks if the document is expired (date-based comparison)
  bool isExpired() {
    final today = _normalize(DateTime.now());
    final expiry = _normalize(expiryDate);
    return today.isAfter(expiry);
  }

  /// Calculates remaining days until expiry
  int daysRemaining() {
    final today = _normalize(DateTime.now());
    final expiry = _normalize(expiryDate);
    return expiry.difference(today).inDays;
  }

  /// Checks if the document will expire within 30 days
  bool isExpiringSoon() {
    final days = daysRemaining();
    return days >= 0 && days <= 30;
  }

  /// Checks if document is suspicious based on confidence score
  bool isSuspicious() {
    return confidenceScore < 0.7;
  }

  /// Returns document status using enum
  DocumentStatus getStatus() {
    if (isExpired()) {
      return DocumentStatus.expired;
    } else if (isExpiringSoon()) {
      return DocumentStatus.expiringSoon;
    } else {
      return DocumentStatus.normal;
    }
  }

  /// Optional: Convert enum to readable string (for UI)
  String getStatusLabel() {
    switch (getStatus()) {
      case DocumentStatus.expired:
        return "EXPIRED";
      case DocumentStatus.expiringSoon:
        return "EXPIRING SOON";
      case DocumentStatus.normal:
        return "NORMAL";
    }
  }
}