import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isLoggedIn;

  LoginState({this.isLoading = false, this.errorMessage, this.isLoggedIn = false});

  LoginState copyWith({bool? isLoading, String? errorMessage, bool? isLoggedIn}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => LoginState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);
      final response = await repo.login(email, password);
      await storageService.saveToken(response.token);
      state = state.copyWith(isLoading: false, isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(() {
  return LoginController();
});
