import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLifecycleProvider =
    StateProvider<AppLifecycleState>((ref) => AppLifecycleState.resumed);
