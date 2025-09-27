// lib/features/authentication/presentation/authentication_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/domain/auth_entities.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository repo;
  AuthenticationBloc(this.repo) : super(const AuthState.initial()) {
    on<LoginWithWallet>(_onLogin);
    on<CheckSession>(_onCheck);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginWithWallet e, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final token = await repo.loginWithTestWallet(e.wallet);
      final me = await repo.loadMe();
      emit(state.copyWith(status: AuthStatus.authenticated, token: token, me: me));
    } catch (err) {
      emit(state.copyWith(status: AuthStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onCheck(CheckSession e, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final me = await repo.loadMe();
      emit(state.copyWith(status: me.isValid ? AuthStatus.authenticated : AuthStatus.unauthenticated, me: me));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await repo.logout();
    emit(const AuthState.initial());
  }
}
