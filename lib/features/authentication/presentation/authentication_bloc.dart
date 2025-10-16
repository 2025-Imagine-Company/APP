// lib/features/authentication/presentation/authentication_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import  'package:flutter/foundation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/domain/auth_entities.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository repo;
  AuthenticationBloc(this.repo) : super(const AuthState.initial()) {
    on<LoginWithWallet>(_onLogin);
    on<LoginWithSignature>(_onLoginSigned);
    on<CheckSession>(_onCheck);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginWithWallet e, Emitter<AuthState> emit) async {
    // debug removed
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final token = await repo.loginWithTestWallet(e.wallet);
      final me = await repo.loadMe();
      // debug removed
      emit(state.copyWith(status: AuthStatus.authenticated, token: token, me: me));
      // debug removed
    } catch (err) {
      // debug removed
      emit(state.copyWith(status: AuthStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onLoginSigned(LoginWithSignature e, Emitter<AuthState> emit) async {
    // debug removed
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final token = await repo.loginWithSignature(
        walletAddress: e.walletAddress,
        message: e.message,
        signature: e.signature,
      );
      // 로그인 직후 /auth/me는 지연될 수 있으므로 우선 토큰만 성공 처리
      emit(state.copyWith(status: AuthStatus.authenticated, token: token));
      // debug removed
      try {
        final me = await repo.loadMe();
        // debug removed
        emit(state.copyWith(status: AuthStatus.authenticated, token: token, me: me));
      } catch (_) {
        // 무시: 토큰은 저장되어 있으므로 사용자는 이후 정상 호출 가능
        // debug removed
      }
    } catch (err) {
      // debug removed
      emit(state.copyWith(status: AuthStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onCheck(CheckSession e, Emitter<AuthState> emit) async {
    // debug removed
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final me = await repo.loadMe();
      // debug removed
      emit(state.copyWith(status: me.isValid ? AuthStatus.authenticated : AuthStatus.unauthenticated, me: me));
      // debug removed
    } catch (_) {
      // debug removed
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    // debug removed
    await repo.logout();
    emit(const AuthState.initial());
  }
}
