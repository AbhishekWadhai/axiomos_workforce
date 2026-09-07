import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static const encryptionKey =
      '2c9ad621595fdca833c40b8d1d6cc427939ab41605a03ee36b51c960b73a68f9';

  static const qrVersion = 'JKLQR1:v1';

  // THIS MUST MATCH SECURE_QR_AAD FROM NODE
  static const secureQrAad = 'jkumar-labour-identity-qr:v1';

  final _algorithm = AesGcm.with256bits();

  Uint8List _base64UrlDecode(String value) {
    var normalized = value.replaceAll('-', '+').replaceAll('_', '/');

    while (normalized.length % 4 != 0) {
      normalized += '=';
    }

    return Uint8List.fromList(base64Decode(normalized));
  }

  Uint8List _hexDecode(String hex) {
    return Uint8List.fromList(
      List.generate(
        hex.length ~/ 2,
        (index) =>
            int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
      ),
    );
  }

  Future<String> decryptQrData(String qrData) async {
    final parts = qrData.split('.');

    if (parts.length != 4) {
      throw const FormatException('Invalid QR format');
    }

    final version = parts[0];
    final nonce = _base64UrlDecode(parts[1]);
    final authTag = _base64UrlDecode(parts[2]);
    final ciphertext = _base64UrlDecode(parts[3]);

    if (version != qrVersion) {
      throw const FormatException('Unsupported QR version');
    }

    final keyBytes = _hexDecode(encryptionKey);

    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag));

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(keyBytes),
      aad: utf8.encode(secureQrAad),
    );

    return utf8.decode(decrypted);
  }
}
