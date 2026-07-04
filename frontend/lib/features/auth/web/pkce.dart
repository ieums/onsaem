import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class Pkce {
  Pkce._(this.verifier, this.challenge);

  final String verifier;
  final String challenge;

  factory Pkce.generate() {
    final verifier = _randomUrlSafe(64);
    final digest = sha256.convert(utf8.encode(verifier));
    final challenge = base64Url.encode(digest.bytes).replaceAll('=', '');
    return Pkce._(verifier, challenge);
  }

  static String _randomUrlSafe(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}