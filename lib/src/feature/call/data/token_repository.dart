import 'package:agora_token_generator/agora_token_generator.dart';

/// Generates Agora RTC tokens locally using the App ID and App Certificate.
///
/// ⚠️  Security note: embedding the App Certificate in the client app means
/// anyone who decompiles the binary can extract it. This is acceptable for
/// internal / demo apps. For a public production app, generate tokens on a
/// server instead and keep the certificate there.
abstract interface class ITokenRepository {
  /// Returns a fresh RTC token valid for [expireSeconds] seconds, or `null`
  /// if token generation is not configured (no App Certificate).
  String? generateToken({
    required String channelName,
    required int uid,
    int expireSeconds = 3600,
  });
}

/// Implementation that generates tokens client-side via [RtcTokenBuilder].
class TokenRepositoryImpl implements ITokenRepository {
  const TokenRepositoryImpl({
    required this.appId,
    required this.appCertificate,
  });

  final String appId;
  final String appCertificate;

  @override
  String? generateToken({
    required String channelName,
    required int uid,
    int expireSeconds = 3600,
  }) {
    if (appId.isEmpty || appCertificate.isEmpty) return null;

    return RtcTokenBuilder.buildTokenWithUid(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: uid,
      tokenExpireSeconds: expireSeconds,
    );
  }
}

/// No-op implementation used when no App Certificate is configured.
class TokenRepositoryNoop implements ITokenRepository {
  const TokenRepositoryNoop();

  @override
  String? generateToken({
    required String channelName,
    required int uid,
    int expireSeconds = 3600,
  }) =>
      null;
}
