import 'dart:convert';
import 'package:crypto/crypto.dart';

const _hashPrefix = r'$HA$';

String hashPassword(String password) {
  final hash = sha256.convert(utf8.encode(password)).toString();
  return '$_hashPrefix$hash';
}

bool verifyPassword(String password, String stored) {
  if (stored.startsWith(_hashPrefix)) {
    final hash = sha256.convert(utf8.encode(password)).toString();
    return stored == '$_hashPrefix$hash';
  }
  return stored == password;
}

bool isHashed(String stored) => stored.startsWith(_hashPrefix);
