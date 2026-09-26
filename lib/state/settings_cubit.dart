import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({this.themeMode = ThemeMode.system, this.lang = 'ru', this.biometrics = false, this.biometricsAsked = false, this.pushAsked = false,
      this.pushAllowed = true, this.channels = const {'orders', 'bonus'}});
  final ThemeMode themeMode;
  final String lang;
  final bool biometrics, biometricsAsked, pushAsked;
  /// Системное разрешение на уведомления (обновлять при resume: FirebaseMessaging.getNotificationSettings()).
  final bool pushAllowed;
  /// Включённые каналы push (PushChannel.name). Промо и «забытая корзина» — только по согласию (opt-in). Синхронизировать: PUT /me/notifications.
  final Set<String> channels;
  SettingsState copyWith({ThemeMode? themeMode, String? lang, bool? biometrics, bool? biometricsAsked, bool? pushAsked, bool? pushAllowed, Set<String>? channels}) => SettingsState(
      themeMode: themeMode ?? this.themeMode, lang: lang ?? this.lang, biometrics: biometrics ?? this.biometrics,
      biometricsAsked: biometricsAsked ?? this.biometricsAsked, pushAsked: pushAsked ?? this.pushAsked, pushAllowed: pushAllowed ?? this.pushAllowed, channels: channels ?? this.channels);
  @override
  List<Object?> get props => [themeMode, lang, biometrics, biometricsAsked, pushAsked, pushAllowed, channels];
}

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());
  void setTheme(ThemeMode m) => emit(state.copyWith(themeMode: m));
  void setLang(String l) => emit(state.copyWith(lang: l));
  void setBiometrics(bool v) => emit(state.copyWith(biometrics: v, biometricsAsked: true));
  void markPushAsked() => emit(state.copyWith(pushAsked: true));
  void setPushAllowed(bool v) => emit(state.copyWith(pushAllowed: v));
  void setChannel(String ch, bool on) => emit(state.copyWith(channels: on ? {...state.channels, ch} : ({...state.channels}..remove(ch))));

  @override
  SettingsState? fromJson(Map<String, dynamic> j) => SettingsState(
      themeMode: ThemeMode.values.byName(j['theme'] as String? ?? 'system'), lang: j['lang'] as String? ?? 'ru',
      biometrics: j['bio'] as bool? ?? false, biometricsAsked: j['bioAsked'] as bool? ?? false, pushAsked: j['push'] as bool? ?? false,
      channels: Set<String>.from(j['channels'] as List? ?? const ['orders', 'bonus']));
  @override
  Map<String, dynamic>? toJson(SettingsState s) => {'theme': s.themeMode.name, 'lang': s.lang, 'bio': s.biometrics, 'bioAsked': s.biometricsAsked, 'push': s.pushAsked, 'channels': s.channels.toList()};
}
