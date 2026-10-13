import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/auth_repository.dart';
import '../ui/widgets/mart_code_input.dart';

/// Шага «имя» нет: после входа сразу в приложение, имя — по желанию в «Личных данных».
enum AuthStep { phone, code, telegram, done }

class AuthState extends Equatable {
  const AuthState({this.step = AuthStep.phone, this.phone = '', this.name = '', this.code = CodeState.idle, this.loading = false, this.tgToken = '', this.tgOk = false,
      this.tgUrl = '', this.tgExpired = false, this.error});
  /// Бот подтвердил номер — показываем «Номер подтверждён» перед следующим шагом.
  final bool tgOk;
  final AuthStep step;
  final String phone, name, tgToken;
  final CodeState code;
  final bool loading;
  /// С бэкендом: готовая ссылка на бота с токеном входа.
  final String tgUrl;
  /// Ссылка входа устарела (10 минут) или уже использована — нужна новая.
  final bool tgExpired;
  /// Почему вход не начался (нет сети, вход недоступен) — текст для покупателя.
  final String? error;
  bool get authed => step == AuthStep.done;
  AuthState copyWith({AuthStep? step, String? phone, String? name, CodeState? code, bool? loading, String? tgToken, bool? tgOk, bool? tgExpired}) => AuthState(
      step: step ?? this.step, phone: phone ?? this.phone, name: name ?? this.name, code: code ?? this.code, loading: loading ?? this.loading, tgToken: tgToken ?? this.tgToken, tgOk: tgOk ?? this.tgOk,
      tgUrl: tgUrl, tgExpired: tgExpired ?? this.tgExpired, error: error);
  @override
  List<Object?> get props => [step, phone, name, code, loading, tgToken, tgOk, tgUrl, tgExpired, error];
}

/// Вход покупателя.
///
/// С бэкендом — только через Telegram-бота: `POST /auth/tg` даёт ссылку `t.me/<бот>?start=<токен>`, покупатель
/// нажимает в боте «Старт» и «Поделиться номером», а приложение опрашивает `GET /auth/tg/{token}` и получает сессию.
/// Сессия хранится в [AuthSession] (Keychain / Keystore) и переживает перезапуск.
///
/// На моке (пустой API_URL или «auth» в API_MOCK) — как в макете: телефон → код 1234, Telegram подтверждается сам.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({this.repo = const AuthRepository()}) : super(_restored()) {
    AuthSession.changes.addListener(_sessionChanged);
    // Сессия с прошлого запуска: проверяем, что она жива, и подтягиваем имя, изменённое на другом устройстве.
    if (state.authed && !AuthRepository.mocked) unawaited(refreshProfile());
  }
  final AuthRepository repo;
  static const _pollEvery = Duration(seconds: 2);
  Timer? _tgPoll;
  bool _checking = false;

  static AuthState _restored() {
    final u = AuthRepository.mocked ? null : AuthSession.user;
    return u == null ? const AuthState() : AuthState(step: AuthStep.done, phone: u.phone, name: u.name);
  }

  /// Сессию закрыли извне (сервер ответил 401) — приложение выходит из аккаунта.
  void _sessionChanged() {
    if (isClosed || AuthRepository.mocked) return;
    if (AuthSession.token == null && state.authed) emit(const AuthState());
  }

  Future<void> refreshProfile() async {
    try {
      final u = await repo.me();
      await AuthSession.updateUser(u);
      if (!isClosed && state.authed) emit(state.copyWith(phone: u.phone, name: u.name));
    } on ApiError {
      // Нет сети — остаёмся с сохранённым профилем; 401 уже обработан через AuthSession.
    }
  }

  // ── мок: телефон и код ──

  Future<void> sendCode(String phone) async {
    emit(state.copyWith(loading: true, phone: phone));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(loading: false, step: AuthStep.code, code: CodeState.idle));
  }

  /// Мок как в макете: верный код — 1234, остальное — ошибка.
  Future<void> verify(String code) async {
    emit(state.copyWith(code: CodeState.checking));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code != '1234') { emit(state.copyWith(code: CodeState.error)); return; }
    emit(state.copyWith(code: CodeState.success));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    emit(state.copyWith(step: AuthStep.done));
  }

  void resetCodeError() { if (state.code == CodeState.error) emit(state.copyWith(code: CodeState.idle)); }

  // ── Telegram ──

  /// Шаг «Вход через Telegram». С бэкендом — новая ссылка входа; ошибка остаётся на экране с «Повторить».
  Future<void> startTelegram() async {
    _tgPoll?.cancel();
    if (AuthRepository.mocked) {
      emit(state.copyWith(step: AuthStep.telegram, tgToken: DateTime.now().millisecondsSinceEpoch.toRadixString(36), tgOk: false));
      return;
    }
    emit(const AuthState(step: AuthStep.telegram, loading: true));
    try {
      final link = await repo.startTelegram();
      if (isClosed || state.step != AuthStep.telegram) return;
      emit(AuthState(step: AuthStep.telegram, tgToken: link.token, tgUrl: link.url));
    } on ApiError catch (e) {
      if (isClosed || state.step != AuthStep.telegram) return;
      emit(AuthState(step: AuthStep.telegram, error: e.message));
    }
  }

  /// Пользователь открыл бота — ждём подтверждения. С бэкендом — опрос раз в 2 с; на моке — через 4 с.
  void waitTelegram() {
    final token = state.tgToken;
    _tgPoll?.cancel();
    if (AuthRepository.mocked) {
      _tgPoll = Timer(const Duration(seconds: 4), () => telegramConfirmed(token, '+7 (700) 133-90-71'));
      return;
    }
    _tgPoll = Timer.periodic(_pollEvery, (_) => checkTelegram());
  }

  /// Один опрос входа: по таймеру и сразу при возврате из Telegram в приложение.
  Future<void> checkTelegram() async {
    final token = state.tgToken;
    if (AuthRepository.mocked || _checking || token.isEmpty || state.step != AuthStep.telegram || state.tgOk || state.tgExpired) return;
    _checking = true;
    try {
      final r = await repo.telegramStatus(token);
      if (isClosed || state.tgToken != token || state.step != AuthStep.telegram) return;
      switch (r) {
        case TgPending(): break;
        case TgExpired():
          _tgPoll?.cancel();
          emit(state.copyWith(tgExpired: true));
        case TgOk(:final accessToken, :final user):
          _tgPoll?.cancel();
          await AuthSession.save(accessToken, user);
          if (isClosed) return;
          emit(state.copyWith(phone: user.phone, name: user.name, tgOk: true));
          await Future<void>.delayed(const Duration(milliseconds: 900));
          if (isClosed || state.step != AuthStep.telegram) return;
          emit(AuthState(step: AuthStep.done, phone: user.phone, name: user.name));
      }
    } on ApiError {
      // Сеть моргнула — попробуем на следующем опросе.
    } finally {
      _checking = false;
    }
  }

  /// Мок: бот подтвердил номер (таймер или deep link 8mart.kz/auth/tg?token=…). С бэкендом номер из ссылки
  /// не принимается — сессию выдаёт только сервер ([checkTelegram]).
  Future<void> telegramConfirmed(String token, String phone) async {
    if (!AuthRepository.mocked) return checkTelegram();
    if (token != state.tgToken) return;
    _tgPoll?.cancel();
    emit(state.copyWith(phone: phone, tgOk: true));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (isClosed || state.step != AuthStep.telegram) return;
    emit(state.copyWith(step: AuthStep.done, tgOk: false));
  }

  void back() { _tgPoll?.cancel(); emit(AuthState(phone: state.phone, name: state.name)); }

  // ── профиль ──

  void changePhone(String phone) => emit(state.copyWith(phone: phone));

  /// Имя в профиле. С бэкендом — `PATCH /me`; false — сохранить не удалось, имя прежнее.
  Future<bool> rename(String name) async {
    final before = state.name;
    emit(state.copyWith(name: name.trim()));
    if (AuthRepository.mocked) return true;
    try {
      final u = await repo.rename(name.trim());
      await AuthSession.updateUser(u);
      if (!isClosed && state.authed) emit(state.copyWith(name: u.name));
      return true;
    } on ApiError {
      if (!isClosed && state.authed) emit(state.copyWith(name: before));
      return false;
    }
  }

  /// Выход на этом устройстве. Сервер закрывает сессию; без сети выходим всё равно — токен с устройства стирается.
  Future<void> logout() async {
    _tgPoll?.cancel();
    if (!AuthRepository.mocked) {
      try { await repo.logout(); } on ApiError { /* сессия на сервере истечёт сама */ }
      await AuthSession.clear();
    }
    if (!isClosed) emit(const AuthState());
  }

  /// Удаление аккаунта (`DELETE /me`). Ошибка — [ApiError]: аккаунт не удалён, покупатель остаётся в нём.
  Future<void> deleteAccount() async {
    if (!AuthRepository.mocked) {
      await repo.deleteAccount();
      await AuthSession.clear();
    }
    if (!isClosed) emit(const AuthState());
  }

  @override
  Future<void> close() {
    _tgPoll?.cancel();
    AuthSession.changes.removeListener(_sessionChanged);
    return super.close();
  }
}
