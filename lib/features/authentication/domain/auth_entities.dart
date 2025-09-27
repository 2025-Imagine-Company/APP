// lib/features/authentication/domain/auth_entities.dart
import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  final String token;
  final String type;
  final String walletAddress;
  final int expiresInHours;
  final String? note;

  const AuthToken({
    required this.token,
    required this.type,
    required this.walletAddress,
    required this.expiresInHours,
    this.note,
  });

  bool get isBearer => type.toLowerCase() == 'bearer';
  Duration get ttl => Duration(hours: expiresInHours);

  @override
  List<Object?> get props => [token, type, walletAddress, expiresInHours, note];
}

class Me extends Equatable {
  final String userId;
  final String walletAddress;
  final int tokenRemainingSeconds;
  final bool isValid;
  final String? nickname; // 서버가 안 줄 수도 있으니 nullable

  const Me({
    required this.userId,
    required this.walletAddress,
    required this.tokenRemainingSeconds,
    required this.isValid,
    this.nickname,
  });

  factory Me.fromJson(Map<String, dynamic> d) => Me(
    userId: d['userId'] as String,
    walletAddress: d['walletAddress'] as String,
    tokenRemainingSeconds: (d['tokenRemainingSeconds'] as num).toInt(),
    isValid: d['isValid'] as bool,
    nickname: d['nickname'] as String?,   // ← 중요
  );

  String get displayName =>
      (nickname != null && nickname!.trim().isNotEmpty)
          ? nickname!.trim()
          : (walletAddress.length <= 10
          ? walletAddress
          : '${walletAddress.substring(0,6)}...${walletAddress.substring(walletAddress.length-4)}');

  @override
  List<Object?> get props =>
      [userId, walletAddress, tokenRemainingSeconds, isValid, nickname];
}
