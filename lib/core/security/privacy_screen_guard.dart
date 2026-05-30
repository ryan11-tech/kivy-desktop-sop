import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyScreenGuard extends StatefulWidget {
  const PrivacyScreenGuard({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyScreenGuard> createState() => _PrivacyScreenGuardState();
}

class _PrivacyScreenGuardState extends State<PrivacyScreenGuard>
    with WidgetsBindingObserver {
  static const _captureProtectionChannel = MethodChannel(
    'zinme_app/capture_protection',
  );

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _screenCaptured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureProtectionChannel.setMethodCallHandler(_handleCaptureMethodCall);
    _refreshScreenCaptureState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureProtectionChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lifecycleState = state);
    _refreshScreenCaptureState();
  }

  Future<dynamic> _handleCaptureMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'screenCaptureChanged':
        final isCaptured = call.arguments == true;
        if (mounted) {
          setState(() => _screenCaptured = isCaptured);
        }
        return null;
      default:
        throw MissingPluginException('Unsupported method: ${call.method}');
    }
  }

  Future<void> _refreshScreenCaptureState() async {
    try {
      final isCaptured =
          await _captureProtectionChannel.invokeMethod<bool>(
            'isScreenCaptured',
          ) ??
          false;
      if (mounted) {
        setState(() => _screenCaptured = isCaptured);
      }
    } on MissingPluginException {
      // Android blocks capture at the window level; other platforms may not
      // provide an active capture-state channel.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldHideContent =
        _screenCaptured || _lifecycleState != AppLifecycleState.resumed;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (shouldHideContent) const Positioned.fill(child: _PrivacyCover()),
      ],
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050505),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.white.withValues(alpha: 0.72),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Sensitive content hidden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
