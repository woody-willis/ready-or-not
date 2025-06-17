import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ready_or_not/models/user.dart';
import 'package:ready_or_not/repository/authentication/authentication.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required this.authenticationRepository,
  }) : super(const LoginState()) {
    on<CheckLoggedIn>(_mapCheckLoggedInEventToState);
    on<LogInGoogle>(_mapLogInGoogleEventToState);
    on<LogInApple>(_mapLogInAppleEventToState);
    on<LogInGuest>(_mapLogInGuestEventToState);

    on<LogOut>((event, emit) async {
      emit(state.copyWith(status: LoginStatus.loading));
      await authenticationRepository.logOut();
      emit(state.copyWith(status: LoginStatus.initial));
    });
  }

  final AuthenticationRepository authenticationRepository;

  void _mapCheckLoggedInEventToState(
      CheckLoggedIn event, Emitter<LoginState> emit) async {
    final currentUser = authenticationRepository.currentUser;
    if (currentUser != User.empty) {
      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: currentUser,
        ),
      );
    } else {
      emit(state.copyWith(status: LoginStatus.initial));
    }
  }

  void _mapLogInGoogleEventToState(
      LogInGoogle event, Emitter<LoginState> emit) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      await authenticationRepository.logInWithGoogle();
      final user = authenticationRepository.currentUser;

      if (user == User.empty) {
        emit(state.copyWith(status: LoginStatus.initial));
        return;
      }

      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: user,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: LoginStatus.error));
    }
  }

  void _mapLogInAppleEventToState(
      LogInApple event, Emitter<LoginState> emit) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      await authenticationRepository.logInWithApple();
      final user = authenticationRepository.currentUser;

      if (user == User.empty) {
        emit(state.copyWith(status: LoginStatus.initial));
        return;
      }

      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: user,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: LoginStatus.error));
    }
  }

  void _mapLogInGuestEventToState(
      LogInGuest event, Emitter<LoginState> emit) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));
      
      await authenticationRepository.logInAsGuest();
      final user = authenticationRepository.currentUser;

      if (user == User.empty) {
        emit(state.copyWith(status: LoginStatus.initial));
        return;
      }

      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: user,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: LoginStatus.error));
    }
  }
}