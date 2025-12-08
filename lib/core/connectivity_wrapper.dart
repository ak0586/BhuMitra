import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'connectivity_service.dart';
import 'localization.dart';

class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper> {
  InternetConnectionStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((status) {
        if (_lastStatus != null && _lastStatus != status) {
          if (status == InternetConnectionStatus.disconnected) {
            _showSnackBar(
              context,
              'no_internet_connection'.tr(ref),
              Colors.red,
              Icons.wifi_off,
            );
          } else if (status == InternetConnectionStatus.connected) {
            _showSnackBar(
              context,
              'internet_connected'.tr(ref),
              Colors.green,
              Icons.wifi,
            );
          }
        }
        _lastStatus = status;
      });
    });

    return widget.child;
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
