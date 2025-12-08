import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final connectivityProvider = StreamProvider<InternetConnectionStatus>((ref) {
  return InternetConnectionChecker().onStatusChange;
});

class ConnectivityService {
  final Ref ref;

  ConnectivityService(this.ref);

  Future<bool> get hasConnection async =>
      await InternetConnectionChecker().hasConnection;
}
