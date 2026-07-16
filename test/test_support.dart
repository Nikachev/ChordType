import 'dart:convert';

import 'package:chordtype/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String testStorageKey = 'chordtype.state.v1';

class MemoryAppStorage implements AppStorage {
  MemoryAppStorage([Map<String, String>? values])
      : _values = <String, String>{...?values};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  String? operator [](String key) => _values[key];
}

String appStateJson({
  String language = 'en',
  String inputLanguage = 'en',
  String hand = 'left',
  bool darkMode = false,
  bool chordHintsEnabled = true,
  Map<String, int> lessonIndexes = const <String, int>{
    'en': 0,
    'ru': 0,
  },
  Map<String, Object?> stats = const <String, Object?>{},
}) {
  return jsonEncode(<String, Object?>{
    'language': language,
    'inputLanguage': inputLanguage,
    'hand': hand,
    'darkMode': darkMode,
    'chordHintsEnabled': chordHintsEnabled,
    'lessonIndexes': lessonIndexes,
    'stats': stats,
  });
}

void configureDesktopView(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
