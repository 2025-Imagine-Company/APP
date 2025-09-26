// lib/features/authentication/presentation/authentication_state.dart
part of 'authentication_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthToken? token;
  final Me? me;
  final String? error;

  const AuthState({
    required this.status,
    this.token,
    this.me,
    this.error,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    AuthToken? token,
    Me? me,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        token: token ?? this.token,
        me: me ?? this.me,
        error: error,
      );

  @override
  List<Object?> get props => [status, token, me, error];
}
