import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Emits whether the device has a network connection: the current state
/// first, then every change.
Stream<bool> networkStatusStream([Connectivity? connectivity]) async* {
  final c = connectivity ?? Connectivity();
  bool hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
  yield hasNetwork(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(hasNetwork);
}

/// Shows a strip across the top of every screen while the device is offline
/// (TRD §9). Resume edits still save to the on-device cache and sync later,
/// but AI features need a connection.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.isOnline, required this.child});

  final Stream<bool> isOnline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: isOnline,
      initialData: true,
      builder: (context, snapshot) {
        final offline = snapshot.data == false;
        final colorScheme = Theme.of(context).colorScheme;
        // Same shape online and offline, so [child] (the app's Navigator)
        // never moves in the tree when the connection changes.
        return Column(
          children: [
            if (offline) _banner(colorScheme) else const SizedBox.shrink(),
            // The banner already covers the status bar, so screens below it
            // shouldn't add their own top padding.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: offline,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _banner(ColorScheme colorScheme) => Material(
    color: colorScheme.inverseSurface,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off, size: 18, color: colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You're offline. Changes are saved on this phone "
                'and sync when you reconnect. AI features need '
                'internet.',
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
