import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  final String token;
  final String type;            // "Bearer"
  final String walletAddress;   // lowercased
  final int expiresInHours;     // 12
  final String? note;           // 선택: "This is a test token - only for development"

  const AuthToken({
    required this.token,
    required this.type,
    required this.walletAddress,
    required this.expiresInHours,
    this.note,
  });

  @override
  List<Object?> get props => [token, type, walletAddress, expiresInHours, note];
}

class Me extends Equatable {
  final String userId;
  final String walletAddress;
  final int tokenRemainingSeconds;
  final bool isValid;
  final String? nickname;       // 서버가 주는 경우만 존재

  const Me({
    required this.userId,
    required this.walletAddress,
    required this.tokenRemainingSeconds,
    required this.isValid,
    this.nickname,
  });

  @override
  List<Object?> get props =>
      [userId, walletAddress, tokenRemainingSeconds, isValid, nickname];
}
