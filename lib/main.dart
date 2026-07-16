import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'chord_data.dart';
import 'chord_engine.dart';
import 'course_data.dart';
import 'lesson_stats.dart';
import 'practice_session.dart';
import 'storage.dart';

part 'practice_widgets.dart';

const String _storageKey = 'chordtype.state.v1';

void main() {
  runApp(const ChordtypeApp());
}

class ChordtypeApp extends StatefulWidget {
  const ChordtypeApp({
    super.key,
    this.storage,
  });

  final AppStorage? storage;

  @override
  State<ChordtypeApp> createState() => _ChordtypeAppState();
}

class _ChordtypeAppState extends State<ChordtypeApp> {
  static const ChordEngine _chordEngine = ChordEngine();

  final FocusNode _focusNode = FocusNode(debugLabel: 'chord-input');
  late final AppStorage _storage;

  CourseLanguage _courseLanguage = CourseLanguage.english;
  CourseLanguage _inputLanguage = CourseLanguage.english;
  HandMode _handMode = HandMode.left;
  bool _darkMode = false;
  bool _chordHintsEnabled = true;
  final Map<CourseLanguage, int> _lessonIndexByLanguage = <CourseLanguage, int>{
    CourseLanguage.english: 0,
    CourseLanguage.russian: 0,
  };
  final Map<String, LessonStats> _statsByLesson = <String, LessonStats>{};
  final PracticeSession _practiceSession =
      PracticeSession(courses.first.lessons.first.target);

  final Set<PhysicalKeyboardKey> _pressedKeys = <PhysicalKeyboardKey>{};
  int _pendingMask = 0;
  ChordModifier? _activeModifier;

  bool _attemptRecorded = false;
  DateTime? _startedAt;
  String _status = 'Ready';

  TrainingCourse get _course => courseFor(_courseLanguage);

  TrainingLesson get _lesson =>
      _course.lessons[_lessonIndexByLanguage[_courseLanguage] ?? 0];

  ChordLayout get _inputLayout => layoutFor(_inputLanguage);

  int get _position => _practiceSession.position;

  int get _errors => _practiceSession.errors;

  int get _strokes => _practiceSession.strokes;

  bool get _completed => _practiceSession.completed;

  List<String> get _typedCharacters => _practiceSession.typedCharacters;

  List<PhysicalChordKey> get _physicalKeys => keysForHand(_handMode);

  bool get _isEnglish => _courseLanguage == CourseLanguage.english;

  String get _readyLabel => _isEnglish ? 'Ready' : 'Готово';

  String get _noSymbolLabel => _isEnglish ? 'No symbol' : 'Нет символа';

  String get _spaceLabel => _isEnglish ? 'Space' : 'Пробел';

  String get _lessonCompletedLabel =>
      _isEnglish ? 'Lesson complete' : 'Урок завершен';

  String get _nowLabel => _isEnglish ? 'Now' : 'Сейчас';

  String get _noChordLabel => _isEnglish ? 'No chord' : 'нет аккорда';

  String get _noHintLabel => _isEnglish ? 'No hint' : 'нет подсказки';

  String get _practiceLabel => _isEnglish ? 'Practice' : 'Практика';

  String get _courseTabLabel => _isEnglish ? 'Course' : 'Курс';

  String get _layoutLabel => _isEnglish ? 'Layout' : 'Раскладка';

  String get _fixErrorsLabel => _isEnglish
      ? 'Press Backspace to fix the mistake'
      : 'Введите Backspace, чтобы исправить ошибку';

  String get _switchLayoutLabel =>
      _isEnglish ? 'Switch layout' : 'Сменить раскладку';

  String get _baseLabel => _isEnglish ? 'Base' : 'База';

  String get _numbersAndSymbolsLabel =>
      _isEnglish ? 'Numbers & symbols' : 'Цифры и символы';

  String get _chordColumnLabel => _isEnglish ? 'Chord' : 'Аккорд';

  String get _outputColumnLabel => _isEnglish ? 'Output' : 'Результат';

  String get _leftHandLabel => _isEnglish ? 'Left' : 'Левая';

  String get _rightHandLabel => _isEnglish ? 'Right' : 'Правая';

  String get _thumbLabel => _isEnglish ? 'Thumb' : 'Большой палец';

  String get _restartTooltip => _isEnglish ? 'Restart lesson' : 'Начать заново';

  String get _nextLessonTooltip =>
      _isEnglish ? 'Next lesson' : 'Следующий урок';

  String get _themeTooltip => _darkMode
      ? (_isEnglish ? 'Use light theme' : 'Включить светлую тему')
      : (_isEnglish ? 'Use dark theme' : 'Включить тёмную тему');

  String get _chordHintsTooltip => _chordHintsEnabled
      ? (_isEnglish ? 'Hide chord hint' : 'Скрыть подсказку аккорда')
      : (_isEnglish ? 'Show chord hint' : 'Показать подсказку аккорда');

  String get _accuracyLabel => _isEnglish ? 'accuracy' : 'точность';

  String get _errorsLabel => _isEnglish ? 'errors' : 'ошибки';

  String get _courseHeading => _isEnglish
      ? '${_courseLanguage.title}: course'
      : '${_courseLanguage.title}: курс';

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? createAppStorage();
    unawaited(_restoreState());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final String? raw = await _storage.read(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final CourseLanguage language = _languageFromCode(
            _stringValue(decoded['language']),
          ) ??
          CourseLanguage.english;
      final CourseLanguage inputLanguage = _languageFromCode(
            _stringValue(decoded['inputLanguage']),
          ) ??
          language;
      final HandMode handMode =
          _handFromCode(_stringValue(decoded['hand'])) ?? HandMode.left;
      final bool darkMode = _boolValue(decoded['darkMode']) ?? false;
      final bool chordHintsEnabled =
          _boolValue(decoded['chordHintsEnabled']) ?? true;
      final Map<CourseLanguage, int> indexes = <CourseLanguage, int>{
        CourseLanguage.english: 0,
        CourseLanguage.russian: 0,
      };
      final Object? lessonIndexes = decoded['lessonIndexes'];
      if (lessonIndexes is Map<String, dynamic>) {
        for (final CourseLanguage value in CourseLanguage.values) {
          final Object? index = lessonIndexes[value.code];
          if (index is int) {
            indexes[value] = index
                .clamp(
                  0,
                  courseFor(value).lessons.length - 1,
                )
                .toInt();
          }
        }
      }

      final Map<String, LessonStats> restoredStats = <String, LessonStats>{};
      final Object? stats = decoded['stats'];
      if (stats is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> entry in stats.entries) {
          final Object? value = entry.value;
          if (value is Map<String, dynamic>) {
            restoredStats[entry.key] = LessonStats.fromJson(value);
          }
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _courseLanguage = language;
        _inputLanguage = inputLanguage;
        _handMode = handMode;
        _darkMode = darkMode;
        _chordHintsEnabled = chordHintsEnabled;
        _lessonIndexByLanguage
          ..clear()
          ..addAll(indexes);
        _statsByLesson
          ..clear()
          ..addAll(restoredStats);
        _practiceSession.reset(_lesson.target);
        _status = _readyLabel;
      });
    } on FormatException {
      return;
    }
  }

  Future<void> _persistState() async {
    final Map<String, Object?> payload = <String, Object?>{
      'language': _courseLanguage.code,
      'inputLanguage': _inputLanguage.code,
      'hand': _handMode.code,
      'darkMode': _darkMode,
      'chordHintsEnabled': _chordHintsEnabled,
      'lessonIndexes': <String, int>{
        for (final MapEntry<CourseLanguage, int> entry
            in _lessonIndexByLanguage.entries)
          entry.key.code: entry.value,
      },
      'stats': <String, Object?>{
        for (final MapEntry<String, LessonStats> entry
            in _statsByLesson.entries)
          entry.key: entry.value.toJson(),
      },
    };
    await _storage.write(_storageKey, jsonEncode(payload));
  }

  CourseLanguage? _languageFromCode(String? code) {
    for (final CourseLanguage value in CourseLanguage.values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }

  String? _stringValue(Object? value) {
    return value is String ? value : null;
  }

  bool? _boolValue(Object? value) {
    return value is bool ? value : null;
  }

  HandMode? _handFromCode(String? code) {
    for (final HandMode value in HandMode.values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final PhysicalKeyboardKey physicalKey = event.physicalKey;
    final int? bit = _bitForKey(physicalKey);
    if (bit == null) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      setState(() {
        _pressedKeys.add(physicalKey);
        _pendingMask |= bit;
      });
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      setState(() {
        _pressedKeys.remove(physicalKey);
      });
      if (_pressedKeys.isEmpty && _pendingMask != 0) {
        final int mask = _pendingMask;
        setState(() {
          _pendingMask = 0;
        });
        _commitChord(mask);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  int? _bitForKey(PhysicalKeyboardKey physicalKey) {
    for (final PhysicalChordKey key in _physicalKeys) {
      if (key.physicalKey == physicalKey) {
        return key.bit;
      }
    }
    return null;
  }

  int get _currentlyPressedMask {
    int mask = 0;
    for (final PhysicalKeyboardKey physicalKey in _pressedKeys) {
      mask |= _bitForKey(physicalKey) ?? 0;
    }
    return mask;
  }

  void _commitChord(int mask) {
    final ChordAction? action = _chordEngine.resolve(
      mask: mask,
      layout: _inputLayout,
      activeModifier: _activeModifier,
    );
    if (action == null) {
      setState(() {
        _status = _noSymbolLabel;
      });
      return;
    }

    switch (action.kind) {
      case ChordActionKind.modifier:
        _toggleModifier(action.modifier!);
        break;
      case ChordActionKind.control:
        _applyControl(action.control!);
        break;
      case ChordActionKind.text:
        _applyText(action.text!);
        break;
    }
  }

  void _toggleModifier(ChordModifier modifier) {
    setState(() {
      final bool armModifier = _activeModifier != modifier;
      _activeModifier = armModifier ? modifier : null;
      _status = armModifier ? _modifierLabel(modifier) : _readyLabel;
    });
  }

  void _applyControl(ChordControl control) {
    switch (control) {
      case ChordControl.backspace:
        setState(() {
          final bool removed = _practiceSession.backspace();
          _status = _practiceSession.hasMistakes
              ? _fixErrorsLabel
              : removed
                  ? _readyLabel
                  : 'Backspace';
          _consumeModifier();
        });
        break;
      case ChordControl.enter:
        _applyText('\n');
        break;
      case ChordControl.switchLayout:
        _switchInputLayout();
        break;
    }
  }

  void _switchInputLayout() {
    setState(() {
      _inputLanguage = _inputLanguage == CourseLanguage.english
          ? CourseLanguage.russian
          : CourseLanguage.english;
      _consumeModifier();
      _status = '$_layoutLabel: ${_inputLanguage.code.toUpperCase()}';
    });
    unawaited(_persistState());
  }

  void _applyText(String value) {
    final String typed = _activeModifier == ChordModifier.shift
        ? shiftedOutputFor(value)
        : value;

    if (_completed) {
      setState(() {
        _consumeModifier();
        _status = _lessonCompletedLabel;
      });
      return;
    }

    _recordAttempt();

    setState(() {
      _consumeModifier();
      final PracticeInputResult result = _practiceSession.enter(typed);
      if (!result.accepted) {
        _status = _fixErrorsLabel;
        return;
      }

      if (result.correct) {
        _status = _readyLabel;
      } else {
        _status = _fixErrorsLabel;
      }

      if (result.completesTarget) {
        _completeLesson();
      } else if (_practiceSession.isFull) {
        _status = _fixErrorsLabel;
      }
    });
  }

  void _consumeModifier() {
    _activeModifier = null;
  }

  void _recordAttempt() {
    if (_attemptRecorded) {
      return;
    }
    _attemptRecorded = true;
    _startedAt = DateTime.now();
    final LessonStats stats = _statsForLesson(_lesson);
    stats.attempts += 1;
    unawaited(_persistState());
  }

  void _completeLesson() {
    if (!_practiceSession.markCompleted()) {
      return;
    }
    final LessonStats stats = _statsForLesson(_lesson);
    final double wpm = _sessionWpm;
    final double accuracy = _sessionAccuracy;
    stats.completions += 1;
    stats.totalErrors += _errors;
    stats.totalStrokes += _strokes;
    stats.lastWpm = wpm;
    stats.lastAccuracy = accuracy;
    stats.bestWpm = math.max(stats.bestWpm, wpm);
    stats.bestAccuracy = math.max(stats.bestAccuracy, accuracy);
    stats.lastCompletedAt = DateTime.now().toIso8601String();
    _status = _lessonCompletedLabel;
    unawaited(_persistState());
  }

  LessonStats _statsForLesson(TrainingLesson lesson) {
    return _statsByLesson.putIfAbsent(lesson.id, LessonStats.new);
  }

  double get _elapsedMinutes {
    final DateTime? startedAt = _startedAt;
    if (startedAt == null) {
      return 0;
    }
    final int milliseconds =
        DateTime.now().difference(startedAt).inMilliseconds;
    return math.max(milliseconds / 60000, 1 / 60);
  }

  double get _sessionWpm {
    if (!_attemptRecorded) {
      return 0;
    }
    return (_position / 5) / _elapsedMinutes;
  }

  double get _sessionAccuracy {
    return _practiceSession.accuracy;
  }

  String _visibleChar(String value) {
    return switch (value) {
      ' ' => _spaceLabel,
      '\n' => 'Enter',
      _ => value,
    };
  }

  String _actionLabel(ChordAction action) {
    return switch (action.kind) {
      ChordActionKind.text => _visibleChar(action.text!),
      ChordActionKind.modifier => _modifierLabel(action.modifier!),
      ChordActionKind.control => _controlLabel(action.control!),
    };
  }

  String _modifierLabel(ChordModifier modifier) {
    return switch (modifier) {
      ChordModifier.shift => 'Shift',
      ChordModifier.numbersAndSymbols => _numbersAndSymbolsLabel,
    };
  }

  String _stepLabel(ChordStep step, String target) {
    final CourseLanguage? switchTo = step.switchTo;
    if (switchTo != null) {
      return '$_switchLayoutLabel: ${switchTo.code.toUpperCase()}';
    }
    final ChordModifier? modifier = step.modifier;
    return modifier == null ? _visibleChar(target) : _modifierLabel(modifier);
  }

  String _controlLabel(ChordControl control) {
    return switch (control) {
      ChordControl.backspace => 'Backspace',
      ChordControl.enter => 'Enter',
      ChordControl.switchLayout => 'EN/RU',
    };
  }

  void _restartLesson() {
    setState(() {
      _practiceSession.reset(_lesson.target);
      _attemptRecorded = false;
      _startedAt = null;
      _pendingMask = 0;
      _pressedKeys.clear();
      _consumeModifier();
      _status = _readyLabel;
    });
    _focusNode.requestFocus();
  }

  void _nextLesson() {
    final int currentIndex = _lessonIndexByLanguage[_courseLanguage] ?? 0;
    final int nextIndex =
        math.min(currentIndex + 1, _course.lessons.length - 1);
    setState(() {
      _lessonIndexByLanguage[_courseLanguage] = nextIndex;
    });
    _restartLesson();
    unawaited(_persistState());
  }

  void _selectLesson(int index) {
    setState(() {
      _lessonIndexByLanguage[_courseLanguage] = index;
    });
    _restartLesson();
    unawaited(_persistState());
  }

  void _selectCourseLanguage(CourseLanguage language) {
    setState(() {
      _courseLanguage = language;
      _inputLanguage = language;
    });
    _restartLesson();
    unawaited(_persistState());
  }

  void _selectHand(HandMode handMode) {
    setState(() {
      _handMode = handMode;
      _pendingMask = 0;
      _pressedKeys.clear();
    });
    _focusNode.requestFocus();
    unawaited(_persistState());
  }

  void _toggleTheme() {
    setState(() {
      _darkMode = !_darkMode;
    });
    _focusNode.requestFocus();
    unawaited(_persistState());
  }

  void _toggleChordHints() {
    setState(() {
      _chordHintsEnabled = !_chordHintsEnabled;
    });
    _focusNode.requestFocus();
    unawaited(_persistState());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chordtype',
      theme: ChordtypeTheme.light,
      darkTheme: ChordtypeTheme.dark,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 180),
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: SafeArea(
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _handleKeyEvent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _focusNode.requestFocus,
                  child: _buildHome(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 980;
        final EdgeInsets padding = EdgeInsets.all(narrow ? 12 : 20);
        final double contentHeight = math.max(
          0,
          constraints.maxHeight - padding.vertical,
        );
        final Widget content =
            narrow ? _buildCompactHome(context) : _buildWideHome(context);

        return Padding(
          padding: padding,
          child: SizedBox(
            height: contentHeight,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildWideHome(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(width: 300, child: _buildSidebar(context)),
        const SizedBox(width: 16),
        Expanded(child: _buildPracticePanel(context)),
        const SizedBox(width: 16),
        SizedBox(width: 360, child: _buildReferencePanel(context)),
      ],
    );
  }

  Widget _buildCompactHome(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: TabBar(
                    tabs: <Widget>[
                      Tab(text: _practiceLabel),
                      Tab(text: _courseTabLabel),
                      Tab(text: _layoutLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _toggleTheme,
                icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: _themeTooltip,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildPracticePanel(context),
                _buildSidebar(context, showThemeToggle: false),
                _buildReferencePanel(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context, {
    bool showThemeToggle = true,
  }) {
    final int currentIndex = _lessonIndexByLanguage[_courseLanguage] ?? 0;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.keyboard, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chordtype',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (showThemeToggle)
                IconButton.filledTonal(
                  onPressed: _toggleTheme,
                  icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
                  tooltip: _themeTooltip,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<CourseLanguage>(
            segments: const <ButtonSegment<CourseLanguage>>[
              ButtonSegment<CourseLanguage>(
                value: CourseLanguage.english,
                label: Text('EN'),
              ),
              ButtonSegment<CourseLanguage>(
                value: CourseLanguage.russian,
                label: Text('RU'),
              ),
            ],
            selected: <CourseLanguage>{_courseLanguage},
            onSelectionChanged: (Set<CourseLanguage> value) {
              _selectCourseLanguage(value.first);
            },
          ),
          const SizedBox(height: 14),
          SegmentedButton<HandMode>(
            segments: <ButtonSegment<HandMode>>[
              ButtonSegment<HandMode>(
                value: HandMode.left,
                icon: const Icon(Icons.keyboard_double_arrow_left),
                label: Text(_leftHandLabel),
              ),
              ButtonSegment<HandMode>(
                value: HandMode.right,
                icon: const Icon(Icons.keyboard_double_arrow_right),
                label: Text(_rightHandLabel),
              ),
            ],
            selected: <HandMode>{_handMode},
            onSelectionChanged: (Set<HandMode> value) {
              _selectHand(value.first);
            },
          ),
          const SizedBox(height: 20),
          Text(
            _courseHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _course.lessons.length,
              itemBuilder: (BuildContext context, int index) {
                final TrainingLesson lesson = _course.lessons[index];
                return _LessonTile(
                  lesson: lesson,
                  index: index,
                  selected: index == currentIndex,
                  stats: _statsByLesson[lesson.id],
                  onTap: () => _selectLesson(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticePanel(BuildContext context) {
    final double progress = _position / _lesson.target.length;
    final ChordHint? hint = _currentChordHint();
    final ColorScheme colors = Theme.of(context).colorScheme;
    return _Panel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lesson.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_lesson.focus} · $_layoutLabel: '
                      '${_inputLanguage.code.toUpperCase()}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    IconButton.filledTonal(
                      key: const ValueKey<String>('chord-hint-toggle'),
                      onPressed: _toggleChordHints,
                      icon: Icon(
                        _chordHintsEnabled
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                      ),
                      tooltip: _chordHintsTooltip,
                    ),
                    IconButton.filledTonal(
                      onPressed: _restartLesson,
                      icon: const Icon(Icons.restart_alt),
                      tooltip: _restartTooltip,
                    ),
                    IconButton.filled(
                      onPressed: _completed ? _nextLesson : null,
                      icon: const Icon(Icons.arrow_forward),
                      tooltip: _nextLessonTooltip,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            _TargetText(
              target: _lesson.target,
              typedCharacters: _typedCharacters,
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: 12),
              _ChordHintCard(
                hint: hint,
                spaceLabel: _spaceLabel,
              ),
            ],
            const SizedBox(height: 16),
            _PracticeMetrics(
              status: hint?.correction == true ? null : _status,
              wpm: _sessionWpm,
              accuracy: _sessionAccuracy,
              errors: _errors,
              accuracyLabel: _accuracyLabel,
              errorsLabel: _errorsLabel,
            ),
            if (_activeModifier != null) ...<Widget>[
              const SizedBox(height: 12),
              _LayerBadge(
                label: _modifierLabel(_activeModifier!),
              ),
            ],
            const SizedBox(height: 20),
            _ChordKeyboard(
              keys: _physicalKeys,
              handMode: _handMode,
              roleLabel: _shortFingerLabel,
              thumbLabel: _thumbLabel,
              pressedMask: _currentlyPressedMask,
              pendingMask: _pendingMask,
              suggestedMask: hint?.mask ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferencePanel(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _layoutLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
            const SizedBox(height: 6),
            TabBar(
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: <Widget>[
                Tab(height: 40, text: _baseLabel),
                Tab(height: 40, text: _numbersAndSymbolsLabel),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _MappingList(
                    key: const ValueKey<String>('mapping-list-base'),
                    layerId: 'base',
                    rows: _baseRows(),
                    chordLabel: _chordColumnLabel,
                    outputLabel: _outputColumnLabel,
                  ),
                  _MappingList(
                    key: const ValueKey<String>(
                      'mapping-list-numbers-symbols',
                    ),
                    layerId: 'numbers-symbols',
                    rows: _directLayerRows(numbersAndSymbolsLayer),
                    chordLabel: _chordColumnLabel,
                    outputLabel: _outputColumnLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MappingRow> _baseRows() {
    final Map<int, String> rows = <int, String>{};
    for (final MapEntry<int, ChordAction> entry in commonActions.entries) {
      final ChordAction action = entry.value;
      rows[entry.key] = action.kind == ChordActionKind.text
          ? _mappingOutput(action.text!)
          : _actionLabel(action);
    }
    for (final MapEntry<int, String> entry in <int, String>{
      ..._inputLayout.letters,
      ..._inputLayout.languageSymbols,
    }.entries) {
      rows[entry.key] = _mappingOutput(entry.value);
    }

    return chordEaseOrder.where(rows.containsKey).map((int mask) {
      return MappingRow(
        chord: chordLabel(mask, _physicalKeys),
        output: rows[mask]!,
      );
    }).toList();
  }

  List<MappingRow> _directLayerRows(Map<int, String> source) {
    return chordEaseOrder.where(source.containsKey).map((int mask) {
      return MappingRow(
        chord: chordLabel(mask, _physicalKeys),
        output: _visibleChar(source[mask]!),
      );
    }).toList();
  }

  String _mappingOutput(String value) {
    final String shifted = shiftedOutputFor(value);
    final bool letter = value.toLowerCase() != value.toUpperCase();
    if (!letter && shifted != value) {
      return '$value / $shifted';
    }
    return _visibleChar(value);
  }

  ChordHint? _currentChordHint() {
    if (_practiceSession.hasMistakes) {
      final List<PhysicalChordKey> keys = _keysForMask(backspaceChord);
      return ChordHint(
        target: 'Backspace',
        mask: backspaceChord,
        chord: chordLabel(backspaceChord, _physicalKeys),
        fingers: keys.map(_fingerLabel).join(', '),
        stepLabel: _fixErrorsLabel,
        correction: true,
      );
    }

    if (!_chordHintsEnabled ||
        _completed ||
        _position >= _lesson.target.length) {
      return null;
    }

    final String target = _lesson.target[_position];
    final List<ChordStep> steps = _chordEngine.planCharacter(
      target: target,
      inputLanguage: _inputLanguage,
    );
    if (steps.isEmpty) {
      return ChordHint(
        target: target,
        mask: 0,
        chord: _noChordLabel,
        fingers: _noHintLabel,
        stepLabel: _nowLabel,
        correction: false,
      );
    }

    int index = 0;
    while (
        index < steps.length - 1 && _modifierIsArmed(steps[index].modifier)) {
      index += 1;
    }

    final ChordStep step = steps[index];
    final List<PhysicalChordKey> keys = _keysForMask(step.mask);
    return ChordHint(
      target: target,
      mask: step.mask,
      chord: chordLabel(step.mask, _physicalKeys),
      fingers: keys.isEmpty
          ? (_isEnglish ? 'none' : 'нет')
          : keys.map(_fingerLabel).join(', '),
      stepLabel: steps.length == 1
          ? _nowLabel
          : '${index + 1}/${steps.length}: ${_stepLabel(step, target)}',
      correction: false,
    );
  }

  bool _modifierIsArmed(ChordModifier? modifier) {
    return modifier != null && modifier == _activeModifier;
  }

  List<PhysicalChordKey> _keysForMask(int mask) {
    return _physicalKeys
        .where((PhysicalChordKey key) => (key.bit & mask) != 0)
        .toList();
  }

  String _fingerLabel(PhysicalChordKey key) {
    return switch (key.role) {
      'миз' => _isEnglish ? 'pinky' : 'мизинец',
      'без' => _isEnglish ? 'ring' : 'безымянный',
      'ср' => _isEnglish ? 'middle' : 'средний',
      'ук' => _isEnglish ? 'index' : 'указательный',
      'б1' => _isEnglish ? 'thumb 1' : 'большой 1',
      'б2' => _isEnglish ? 'thumb 2' : 'большой 2',
      _ => key.role,
    };
  }

  String _shortFingerLabel(PhysicalChordKey key) {
    return switch (key.role) {
      'миз' => _isEnglish ? 'pinky' : 'мизинец',
      'без' => _isEnglish ? 'ring' : 'безымянный',
      'ср' => _isEnglish ? 'middle' : 'средний',
      'ук' => _isEnglish ? 'index' : 'указательный',
      'б1' => '1',
      'б2' => '2',
      _ => key.role,
    };
  }
}
