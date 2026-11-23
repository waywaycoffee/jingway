// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../flavors/app_flavor.dart';
import 'theme_ui_model.dart';

part 'theme_logic.g.dart';

@riverpod
class ThemeLogic extends _$ThemeLogic {
  @override
  ThemeUiModel build() {
    final bool jingway = FlavorConfig.isJingwayProduct;
    if (!Hive.isBoxOpen('prefs')) {
      // Widget tests and early boot can build before prefs are opened.
      return ThemeUiModel(
        themeMode: jingway ? ThemeMode.light : ThemeMode.dark,
      );
    }
    final Box<String> prefsBox = Hive.box<String>('prefs');
    if (jingway) {
      // One-shot migrate off AE dark default onto 宣纸浅色.
      if (prefsBox.get('themeJingwayXuanV1') != '1') {
        prefsBox.put('themeJingwayXuanV1', '1');
        prefsBox.put('themeMode', ThemeMode.light.toString());
      }
    } else if (prefsBox.get('themeDarkCanvasV4') != '1') {
      // AE product default is dark canvas.
      prefsBox.put('themeDarkCanvasV4', '1');
      prefsBox.put('themeMode', ThemeMode.dark.toString());
    }
    final ThemeMode fallback =
        jingway ? ThemeMode.light : ThemeMode.dark;
    ThemeMode themeMode = fallback;
    final String mode =
        prefsBox.get('themeMode', defaultValue: fallback.toString()) as String;
    switch (mode) {
      case 'ThemeMode.dark':
        themeMode = ThemeMode.dark;
      case 'ThemeMode.light':
        themeMode = ThemeMode.light;
      case 'ThemeMode.system':
        themeMode = ThemeMode.system;
    }
    return ThemeUiModel(themeMode: themeMode);
  }

  void setThemeMode(ThemeMode mode) {
    Hive.box<String>('prefs').put('themeMode', mode.toString());
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme() {
    if (state.themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
