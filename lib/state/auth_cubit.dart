import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ui/widgets/mart_code_input.dart';

enum AuthStep { phone, code, telegram, name, done }

class AuthState extends Equatable {
  const AuthState({this.step = AuthStep.phone, this.phone = '', this.name = '', this.code = CodeState.idle, this.loading = false, this.tgToken = ''});
  final AuthStep step;
  final String phone, name, tgToken;
  final CodeState code;
  final bool loading;
  bool get authed => step == AuthStep.done;
  AuthState copyWith({AuthStep? step, String? phone, String? name, CodeState? code, bool? loading, String? tgToken}) => AuthState(
      step: step ?? this.step, phone: phone ?? this.phone, name: name ?? this.name, code: code ?? this.code, loading: loading ?? this.loading, tgToken: tgToken ?? this.tgToken);
  @override
  List<Object?> get props => [step, phone, name, code, loading, tgToken];
}

/// МОК авторизации. В проде: POST /auth/code {phone, channel:'whatsapp'} → POST /auth/verify {phone, code}
/// → {accessToken, refreshToken, user{name?}}. refreshToken — в flutter_secure_storage (открывается Face ID, если включено).
/// Telegram: POST /auth/tg → {token}; открыть t.me/<bot>?start=<token>; бэкенд подтверждает push/событием или GET /auth/tg/{token}.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());
  Timer? _tgPoll;

  Future<void> sendCode(String phone) async {
    emit(state.copyWith(loading: true, phone: phone));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(loading: false, step: AuthStep.code, code: CodeState.idle));
  }

  /// Мок: «0000» — неверный код, остальное — успех. Новый пользователь → шаг имени.
  Future<void> verify(String code) async {
    emit(state.copyWith(code: CodeState.checking));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code == '0000') { emit(state.copyWith(code: CodeState.error)); return; }
    emit(state.copyWith(code: CodeState.success));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final isNew = state.name.isEmpty;
    emit(state.copyWith(step: isNew ? AuthStep.name : AuthStep.done));
  }

  void resetCodeError() { if (state.code == CodeState.error) emit(state.copyWith(code: CodeState.idle)); }

  String startTelegram() {
    final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    emit(state.copyWith(step: AuthStep.telegram, tgToken: token));
    _tgPoll?.cancel();
    // Мок подтверждения ботом через 4 с. В проде — поллинг GET /auth/tg/{token} каждые 2 с или push.
    _tgPoll = Timer(const Duration(seconds: 4), () => telegramConfirmed(token, '+7 (700) 133-90-71'));
    return token;
  }

  /// Вызывается и из deep link 8mart.kz/auth/tg?token=…
  void telegramConfirmed(String token, String phone) {
    if (token != state.tgToken) return;
    _tgPoll?.cancel();
    emit(state.copyWith(phone: phone, step: state.name.isEmpty ? AuthStep.name : AuthStep.done));
  }

  void setName(String name) => emit(state.copyWith(name: name.trim(), step: AuthStep.done));
  void back() => emit(state.copyWith(step: AuthStep.phone, code: CodeState.idle));
  void changePhone(String phone) => emit(state.copyWith(phone: phone));
  void rename(String name) => emit(state.copyWith(name: name.trim()));
  void logout() => emit(const AuthState());

  @override
  Future<void> close() { _tgPoll?.cancel(); return super.close(); }
}
