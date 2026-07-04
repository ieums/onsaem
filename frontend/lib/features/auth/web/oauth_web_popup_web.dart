import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// 팝업을 띄우고 콜백 페이지가 postMessage로 보내는 JSON 문자열을 기다린다.
/// 사용자가 팝업을 그냥 닫으면 null, 2분 넘게 응답 없으면 타임아웃으로 null.
Future<Map<String, String>?> openOAuthPopup({
  required String url,
  required String popupName,
}) async {
  final popup = web.window.open(url, popupName, 'width=480,height=640');
  if (popup == null) return null;

  final completer = Completer<Map<String, String>?>();
  late final StreamSubscription<web.Event> messageSub;
  Timer? closeWatcher;

  void finish(Map<String, String>? result) {
    if (completer.isCompleted) return;
    messageSub.cancel();
    closeWatcher?.cancel();
    completer.complete(result);
  }

  messageSub = web.window.onMessage.listen((web.Event rawEvent) {
    final event = rawEvent as web.MessageEvent;
    if (event.origin != web.window.location.origin) return;
    final data = event.data;
    if (data == null) return;
    String text;
    try {
      text = (data as JSString).toDart;
    } catch (_) {
      return;
    }
    Map<String, dynamic> map;
    try {
      map = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (map['source'] != 'ieum-oauth') return;
    finish(map.map((k, v) => MapEntry(k, v?.toString() ?? '')));
  });

  closeWatcher = Timer.periodic(const Duration(milliseconds: 500), (timer) {
    if (popup.closed) {
      timer.cancel();
      finish(null);
    }
  });

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      popup.close();
      finish(null);
      return null;
    },
  );
}