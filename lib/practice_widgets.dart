part of 'main.dart';

class MappingRow {
  const MappingRow({required this.chord, required this.output});

  final String chord;
  final String output;
}

class ChordHint {
  const ChordHint({
    required this.target,
    required this.mask,
    required this.chord,
    required this.fingers,
    required this.stepLabel,
    required this.correction,
  });

  final String target;
  final int mask;
  final String chord;
  final String fingers;
  final String stepLabel;
  final bool correction;
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(
              alpha: colors.brightness == Brightness.dark ? 0.3 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.selected,
    required this.onTap,
    this.stats,
  });

  final TrainingLesson lesson;
  final int index;
  final bool selected;
  final LessonStats? stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int completions = stats?.completions ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.focus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? colors.onPrimaryContainer
                                  .withValues(alpha: 0.72)
                              : colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completions > 0)
                  Icon(Icons.check_circle, color: colors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetText extends StatelessWidget {
  const _TargetText({
    required this.target,
    required this.typedCharacters,
  });

  final String target;
  final List<String> typedCharacters;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle targetStyle = switch (target.length) {
      > 240 => textTheme.titleLarge!,
      > 120 => textTheme.headlineSmall!,
      _ => textTheme.headlineMedium!,
    };
    final TextStyle baseStyle = targetStyle.copyWith(
      height: 1.55,
      letterSpacing: 0,
      fontWeight: FontWeight.w700,
    );
    final List<TextSpan> spans = <TextSpan>[];
    for (int index = 0; index < target.length; index += 1) {
      final String char = target[index];
      TextStyle style = baseStyle.copyWith(color: colors.onSurface);
      if (index < typedCharacters.length) {
        style = typedCharacters[index] == char
            ? style.copyWith(color: colors.tertiary)
            : style.copyWith(
                color: colors.onError,
                backgroundColor: colors.error,
              );
      } else if (index == typedCharacters.length) {
        style = style.copyWith(
          color: colors.onPrimary,
          backgroundColor: colors.primary,
        );
      } else {
        style = style.copyWith(color: colors.onSurfaceVariant);
      }
      spans.add(TextSpan(text: char, style: style));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: RichText(text: TextSpan(children: spans)),
      ),
    );
  }
}

class _ChordHintCard extends StatelessWidget {
  const _ChordHintCard({
    required this.hint,
    required this.spaceLabel,
  });

  final ChordHint hint;
  final String spaceLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color containerColor =
        hint.correction ? colors.errorContainer : colors.tertiaryContainer;
    final Color borderColor = hint.correction ? colors.error : colors.tertiary;
    final Color contentColor =
        hint.correction ? colors.onErrorContainer : colors.onTertiaryContainer;

    return DecoratedBox(
      key: const ValueKey<String>('chord-hint'),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                _visibleTarget(hint.target, spaceLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: hint.correction ? colors.error : colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hint.stepLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hint.chord} · ${hint.fingers}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: contentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _visibleTarget(String value, String spaceLabel) {
    return switch (value) {
      ' ' => spaceLabel,
      '\n' => 'Enter',
      _ => value,
    };
  }
}

class _PracticeMetrics extends StatelessWidget {
  const _PracticeMetrics({
    required this.status,
    required this.wpm,
    required this.accuracy,
    required this.errors,
    required this.accuracyLabel,
    required this.errorsLabel,
  });

  final String? status;
  final double wpm;
  final double accuracy;
  final int errors;
  final String accuracyLabel;
  final String errorsLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (status != null)
          Text(
            status!,
            key: const ValueKey<String>('practice-status'),
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        _InlineMetric(label: 'wpm', value: wpm.toStringAsFixed(1)),
        _InlineMetric(
          label: accuracyLabel,
          value: '${accuracy.toStringAsFixed(0)}%',
        ),
        _InlineMetric(label: errorsLabel, value: '$errors'),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label ',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerBadge extends StatelessWidget {
  const _LayerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.secondary),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChordKeyboard extends StatelessWidget {
  const _ChordKeyboard({
    required this.keys,
    required this.handMode,
    required this.roleLabel,
    required this.thumbLabel,
    required this.pressedMask,
    required this.pendingMask,
    required this.suggestedMask,
  });

  final List<PhysicalChordKey> keys;
  final HandMode handMode;
  final String Function(PhysicalChordKey key) roleLabel;
  final String thumbLabel;
  final int pressedMask;
  final int pendingMask;
  final int suggestedMask;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = constraints.maxWidth < 520 ? 8 : 12;
        return _buildHandKeyboard(context, constraints, gap);
      },
    );
  }

  Widget _buildHandKeyboard(
    BuildContext context,
    BoxConstraints constraints,
    double gap,
  ) {
    final double keyWidth = math.min(
      118.0,
      math.max(0, (constraints.maxWidth - gap * 3) / 4),
    );
    const double fingerKeyHeight = 88;
    const double thumbKeyHeight = 48;
    const double thumbGroupPadding = 6;
    const double thumbLabelHeight = 14;
    final double fingerRowWidth = keyWidth * 4 + gap * 3;
    final double thumbKeyWidth = math.min(keyWidth, 96);
    final bool rightHand = handMode == HandMode.right;
    final List<PhysicalChordKey> orderedFingerKeys = rightHand
        ? <PhysicalChordKey>[
            _keyForRole('ук'),
            _keyForRole('ср'),
            _keyForRole('без'),
            _keyForRole('миз'),
          ]
        : <PhysicalChordKey>[
            _keyForRole('миз'),
            _keyForRole('без'),
            _keyForRole('ср'),
            _keyForRole('ук'),
          ];
    final Widget thumbGroup = _buildThumbGroup(
      context,
      thumbKeyWidth,
      thumbKeyHeight,
      gap,
      thumbGroupPadding,
      thumbLabelHeight,
    );

    return Center(
      child: SizedBox(
        width: fingerRowWidth,
        child: Column(
          key: const ValueKey<String>('chord-keyboard-row'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              key: const ValueKey<String>('chord-finger-row'),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final PhysicalChordKey key
                    in orderedFingerKeys) ...<Widget>[
                  if (key != orderedFingerKeys.first) SizedBox(width: gap),
                  _keyCap(key, keyWidth, height: fingerKeyHeight),
                ],
              ],
            ),
            SizedBox(height: gap),
            SizedBox(
              width: fingerRowWidth,
              child: Align(
                alignment:
                    rightHand ? Alignment.centerLeft : Alignment.centerRight,
                child: thumbGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbGroup(
    BuildContext context,
    double keyWidth,
    double keyHeight,
    double gap,
    double padding,
    double labelHeight,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: thumbLabel,
      child: DecoratedBox(
        key: const ValueKey<String>('chord-thumb-group'),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: labelHeight,
                child: Text(
                  thumbLabel,
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                key: const ValueKey<String>('chord-thumb-row'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _keyCap(_keyForRole('б1'), keyWidth, height: keyHeight),
                  SizedBox(width: gap),
                  _keyCap(_keyForRole('б2'), keyWidth, height: keyHeight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PhysicalChordKey _keyForRole(String role) {
    return keys.firstWhere((PhysicalChordKey key) => key.role == role);
  }

  Widget _keyCap(
    PhysicalChordKey key,
    double width, {
    double height = 86,
  }) {
    return _ChordKeyCap(
      width: width,
      height: height,
      keyData: key,
      roleLabel: roleLabel(key),
      pressed: (pressedMask & key.bit) != 0,
      pending: (pendingMask & key.bit) != 0,
      suggested: (suggestedMask & key.bit) != 0,
    );
  }
}

class _ChordKeyCap extends StatelessWidget {
  const _ChordKeyCap({
    required this.width,
    required this.height,
    required this.keyData,
    required this.roleLabel,
    required this.pressed,
    required this.pending,
    required this.suggested,
  });

  final double width;
  final double height;
  final PhysicalChordKey keyData;
  final String roleLabel;
  final bool pressed;
  final bool pending;
  final bool suggested;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = pressed
        ? colors.primary
        : pending
            ? colors.primaryContainer
            : suggested
                ? colors.tertiaryContainer
                : colors.surfaceContainerLow;
    final Color borderColor = pressed || pending
        ? colors.primary
        : suggested
            ? colors.tertiary
            : colors.outlineVariant;
    final Color textColor = pressed
        ? colors.onPrimary
        : pending
            ? colors.onPrimaryContainer
            : suggested
                ? colors.onTertiaryContainer
                : colors.onSurface;
    final bool compact = height < 60;
    return SizedBox(
      key: ValueKey<String>('chord-key-size-${keyData.bit}'),
      width: width,
      height: height,
      child: AnimatedContainer(
        key: ValueKey<String>('chord-key-${keyData.bit}'),
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: pressed || pending || suggested ? 1.8 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                keyData.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact
                      ? (keyData.label.length > 2 ? 13 : 16)
                      : (keyData.label.length > 2 ? 18 : 24),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 2 : 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    roleLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.72),
                      fontSize: compact ? 11 : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MappingList extends StatelessWidget {
  const _MappingList({
    super.key,
    required this.layerId,
    required this.rows,
    required this.chordLabel,
    required this.outputLabel,
  });

  final String layerId;
  final List<MappingRow> rows;
  final String chordLabel;
  final String outputLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        key: ValueKey<String>('mapping-$layerId-frame'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: <Widget>[
            ColoredBox(
              color: colors.surfaceContainerHighest,
              child: SizedBox(
                height: 32,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 96,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          outputLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          chordLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                separatorBuilder: (BuildContext context, int index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.65),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final MappingRow row = rows[index];
                  final bool singleCharacter = row.output.runes.length == 1;
                  final bool symbolOutput =
                      singleCharacter || row.output.contains(' / ');
                  return SizedBox(
                    key: ValueKey<String>(
                      'mapping-$layerId-row-${row.output}',
                    ),
                    height: 42,
                    child: ColoredBox(
                      color: index.isEven
                          ? colors.surface
                          : colors.surfaceContainerLow,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ColoredBox(
                            key: ValueKey<String>(
                              'mapping-$layerId-output-${row.output}',
                            ),
                            color: colors.primary,
                            child: SizedBox(
                              width: 96,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      row.output,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: colors.onPrimary,
                                        fontFamily:
                                            symbolOutput ? 'monospace' : null,
                                        fontSize: singleCharacter ? 18 : 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: symbolOutput ? 0.2 : 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  row.chord,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
