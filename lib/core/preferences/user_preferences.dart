class UserPreferences {
  const UserPreferences({
    required this.themeMode,
    required this.primaryHex,
    required this.fontSize,
    required this.language,
    required this.pinEnabled,
  });

  static const defaults = UserPreferences(
    themeMode: 'dark',
    primaryHex: '#8B0000',
    fontSize: 'Medium',
    language: 'English',
    pinEnabled: true,
  );

  final String themeMode;
  final String primaryHex;
  final String fontSize;
  final String language;
  final bool pinEnabled;

  UserPreferences copyWith({
    String? themeMode,
    String? primaryHex,
    String? fontSize,
    String? language,
    bool? pinEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      primaryHex: primaryHex ?? this.primaryHex,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
      pinEnabled: pinEnabled ?? this.pinEnabled,
    );
  }
}
