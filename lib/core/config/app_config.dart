/// Compile-time app configuration sourced from `--dart-define` flags.
class AppConfig {
  const AppConfig._();

  /// When true, the SOP catalog falls back to bundled mock data if the network
  /// call fails. Defaults to false so production never silently serves mocks.
  /// Enable with `--dart-define=ZINME_USE_MOCK_SOPS=true`.
  static const bool useMockSops = bool.fromEnvironment(
    'ZINME_USE_MOCK_SOPS',
    defaultValue: false,
  );

  /// When true, the recipe catalog falls back to bundled mock data if the
  /// network call fails. Defaults to false so production never silently serves
  /// mocks. Enable with `--dart-define=ZINME_USE_MOCK_RECIPES=true`.
  static const bool useMockRecipes = bool.fromEnvironment(
    'ZINME_USE_MOCK_RECIPES',
    defaultValue: false,
  );
}
