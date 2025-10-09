// lib/features/authentication/presentation/authentication_event.dart
part of 'authentication_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginWithWallet extends AuthEvent {
  final String wallet;
  const LoginWithWallet(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class LoginWithSignature extends AuthEvent {
  final String walletAddress;
  final String message;
  final String signature;
  const LoginWithSignature({required this.walletAddress, required this.message, required this.signature});
  @override
  List<Object?> get props => [walletAddress, message, signature];
}

class CheckSession extends AuthEvent {
  const CheckSession();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
