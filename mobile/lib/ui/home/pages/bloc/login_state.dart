part of 'login_bloc.dart';

enum LoginStatus { initial, success, error, loading }

extension LoginStatusX on LoginStatus {
  bool get isInitial => this == LoginStatus.initial;
  bool get isSuccess => this == LoginStatus.success;
  bool get isError => this == LoginStatus.error;
  bool get isLoading => this == LoginStatus.loading;
}

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    User? user,
  }) : user = user ?? User.empty;

  final User user;
  final LoginStatus status;

  @override
  List<Object?> get props => [status, user];

  LoginState copyWith({
    User? user,
    LoginStatus? status,
  }) {
    return LoginState(
      user: user ?? this.user,
      status: status ?? this.status,
    );
  }
}