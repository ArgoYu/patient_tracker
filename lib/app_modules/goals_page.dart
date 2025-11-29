part of 'package:patient_tracker/app_modules.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({
    super.key,
    required this.goals,
    required this.mealMenu,
    required this.mealSelections,
    required this.mealDeliveryWindows,
    required this.completedMeals,
    required this.mealNotes,
    required this.onSelectMealOption,
    required this.onChangeMealTime,
    required this.onToggleMealCompleted,
    required this.onUpdateMealNotes,
  });
  final List<Goal> goals;
  final Map<MealSlot, List<MealOption>> mealMenu;
  final Map<MealSlot, int> mealSelections;
  final Map<MealSlot, TimeOfDay> mealDeliveryWindows;
  final Set<MealSlot> completedMeals;
  final String mealNotes;
  final void Function(MealSlot slot, int index) onSelectMealOption;
  final void Function(MealSlot slot, TimeOfDay time) onChangeMealTime;
  final void Function(MealSlot slot, bool value) onToggleMealCompleted;
  final ValueChanged<String> onUpdateMealNotes;
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  static const List<GoalCategory> _categoryOrder = [
    GoalCategory.diet,
    GoalCategory.exercises,
    GoalCategory.meditation,
    GoalCategory.sleep,
    GoalCategory.hydration,
    GoalCategory.social,
    GoalCategory.treatment,
  ];
  GoalSortMode _sortMode = GoalSortMode.category;
  bool _hasShownOverallCelebration = false;
  final Map<String, _CustomCategoryOption> _customCategories = {};

  List<_CustomCategoryOption> get _customCategoryOptions {
    final options = _customCategories.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return options;
  }

  void _handleCustomCategoryCreated(String name, IconData? icon) {
    _registerCustomCategory(name, icon);
  }

  void _registerCustomCategory(String name, IconData? icon) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final key = trimmed.toLowerCase();
    final existing = _customCategories[key];
    _customCategories[key] = _CustomCategoryOption(
      name: existing?.name ?? trimmed,
      icon: icon ?? existing?.icon,
    );
  }

  void _syncCustomCategories() {
    for (final goal in widget.goals) {
      if (goal.category != GoalCategory.custom) continue;
      final name = goal.customCategoryName?.trim();
      if (name == null || name.isEmpty) continue;
      _registerCustomCategory(name, goal.customCategoryIcon);
    }
  }

  bool get _allGoalsComplete =>
      widget.goals.isNotEmpty && widget.goals.every((g) => g.progress >= 0.999);

  Future<void> _triggerOverallCelebrationIfNeeded() async {
    if (_hasShownOverallCelebration || !_allGoalsComplete) return;
    _hasShownOverallCelebration = true;
    await _showGrandCelebration();
  }

  Future<void> _showGrandCelebration() {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: GoalsVictoryOverlay(goals: List<Goal>.from(widget.goals)),
        ),
      ),
    );
  }

  Future<void> _showGoalCelebration(Goal goal) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: GoalCompletionCelebration(goal: goal),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _syncCustomCategories();
    if (_allGoalsComplete) {
      _hasShownOverallCelebration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showGrandCelebration();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GoalsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goals != widget.goals) {
      _syncCustomCategories();
    }
  }

  Future<void> _addGoal() async {
    final result = await fadeDialog<_GoalFormResult>(
      context,
      _GoalFormDialog(
        customCategories: _customCategoryOptions,
        onRegisterCustomCategory: _handleCustomCategoryCreated,
        initialCategory: GoalCategory.diet,
        initialCustomCategoryName: null,
        initialCustomCategoryIcon: null,
      ),
    );
    if (result != null && result.title.trim().isNotEmpty) {
      final instructions = result.instructions.trim();
      setState(() {
        widget.goals.add(
          Goal(
            title: result.title.trim(),
            progress: 0,
            instructions: instructions.isEmpty ? null : instructions,
            category: result.category,
            frequency: result.frequency,
            timesPerPeriod: result.timesPerPeriod,
            startDate: result.startDate,
            endDate: result.endDate,
            reminder: result.reminder,
            importance: result.importance,
            customCategoryName: result.customCategoryName,
          ),
        );
        if (result.category == GoalCategory.custom &&
            (result.customCategoryName?.trim().isNotEmpty ?? false)) {
          _handleCustomCategoryCreated(
            result.customCategoryName!,
            result.customCategoryIcon,
          );
        }
        _syncCustomCategories();
        _hasShownOverallCelebration = false;
      });
    }
  }

  double _averageProgress() {
    if (widget.goals.isEmpty) return 0;
    final total = widget.goals.fold<double>(0, (sum, g) => sum + g.progress);
    return total / widget.goals.length;
  }

  void _handleGoalCheckIn(Goal goal) {
    if (goal.progress >= 0.999) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Goal already complete'),
          content: Text('“${goal.title}” is already at 100%.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final wasIncomplete = goal.progress < 0.999;
    setState(() {
      goal.progress = (goal.progress + 0.1).clamp(0, 1);
      if (!_allGoalsComplete) {
        _hasShownOverallCelebration = false;
      }
    });
    final nowComplete = goal.progress >= 0.999;
    if (wasIncomplete && nowComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showGoalCelebration(goal).whenComplete(() {
          if (!mounted) return;
          _triggerOverallCelebrationIfNeeded();
        });
      });
    } else if (_allGoalsComplete) {
      _triggerOverallCelebrationIfNeeded();
    }
  }

  void _moveGoal(Goal goal, int offset) {
    final currentIndex = widget.goals.indexOf(goal);
    if (currentIndex == -1) return;
    final newIndex = (currentIndex + offset).clamp(0, widget.goals.length - 1);
    if (newIndex == currentIndex) return;
    setState(() {
      widget.goals
        ..removeAt(currentIndex)
        ..insert(newIndex, goal);
    });
  }

  int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * 60 + a.minute;
    final bMinutes = b.hour * 60 + b.minute;
    return aMinutes.compareTo(bMinutes);
  }

  Widget _buildGoalCardWidget(
    Goal goal, {
    bool isLast = false,
    bool isFirst = false,
    bool enableMoveControls = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: _GoalCard(
        goal: goal,
        onCheckIn: () => _handleGoalCheckIn(goal),
        onEdit: () {
          final currentIndex = widget.goals.indexOf(goal);
          if (currentIndex == -1) return;
          _showEditSheet(goal, currentIndex);
        },
        onDelete: () => setState(() {
          widget.goals.remove(goal);
        }),
        onImportanceChanged: (value) => setState(() => goal.importance = value),
        onMoveUp:
            enableMoveControls && !isFirst ? () => _moveGoal(goal, -1) : null,
        onMoveDown:
            enableMoveControls && !isLast ? () => _moveGoal(goal, 1) : null,
      ),
    );
  }

  List<Widget> _buildGoalsList(BuildContext context) {
    if (_sortMode == GoalSortMode.category) {
      return _buildCategorizedGoals(context);
    }
    final enableMoves = _sortMode == GoalSortMode.custom;
    final sorted = List<Goal>.from(widget.goals);
    switch (_sortMode) {
      case GoalSortMode.category:
        break;
      case GoalSortMode.startDate:
        sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case GoalSortMode.reminderTime:
        sorted.sort((a, b) => _compareTimeOfDay(a.reminder, b.reminder));
        break;
      case GoalSortMode.importance:
        sorted.sort((a, b) {
          final diff = b.importance.weight() - a.importance.weight();
          if (diff != 0) return diff;
          return a.startDate.compareTo(b.startDate);
        });
        break;
      case GoalSortMode.custom:
        break;
    }
    final widgets = <Widget>[];
    for (var i = 0; i < sorted.length; i++) {
      final goal = sorted[i];
      widgets.add(
        _buildGoalCardWidget(
          goal,
          isLast: i == sorted.length - 1,
          isFirst: i == 0,
          enableMoveControls: enableMoves,
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGoals = widget.goals.length;
    final hasDietPlanData =
        widget.mealMenu.values.any((options) => options.isNotEmpty);
    final shouldShowDietSection = totalGoals > 0 && hasDietPlanData;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<GoalSortMode>(
            tooltip: 'Sort goals',
            icon: Icon(_sortMode.icon()),
            onSelected: (value) => setState(() => _sortMode = value),
            itemBuilder: (ctx) => GoalSortMode.values
                .map(
                  (mode) => PopupMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(
                          mode.icon(),
                          size: 18,
                          color: mode == _sortMode
                              ? Theme.of(ctx).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(mode.label()),
                        if (mode == _sortMode) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(onPressed: _addGoal, icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (totalGoals > 0)
            Glass(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall progress',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _averageProgress()),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (widget.goals.isEmpty) ...[
            const SizedBox(height: 16),
            const Glass(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag, size: 38),
                    SizedBox(height: 14),
                    Text(
                      'Set your first goal',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Goals keep your care plan actionable. Tap + to add your first milestone.',
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (_sortMode == GoalSortMode.custom) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Use the arrow buttons on each goal to arrange your custom order.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
            ],
            ..._buildGoalsList(context),
          ],
          if (shouldShowDietSection) ...[
            const SizedBox(height: 24),
            _DietPlanSection(
              menu: widget.mealMenu,
              selections: widget.mealSelections,
              deliveryWindows: widget.mealDeliveryWindows,
              completed: widget.completedMeals,
              notes: widget.mealNotes,
              onSelectMeal: widget.onSelectMealOption,
              onChangeWindow: widget.onChangeMealTime,
              onToggleCompleted: widget.onToggleMealCompleted,
              onNotesChanged: widget.onUpdateMealNotes,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditSheet(Goal goal, int index) async {
    final title = TextEditingController(text: goal.title);
    final instructions = TextEditingController(text: goal.instructions ?? '');
    final timesController =
        TextEditingController(text: goal.timesPerPeriod.toString());
    var frequency = goal.frequency;
    var category = goal.category;
    var startDate = DateUtils.dateOnly(goal.startDate);
    DateTime? endDate =
        goal.endDate == null ? null : DateUtils.dateOnly(goal.endDate!);
    String? timesError;
    var reminder = goal.reminder;
    double progress = goal.progress;
    var importance = goal.importance;
    final customCategoryController =
        TextEditingController(text: goal.customCategoryName ?? '');
    String? customCategoryError;
    IconData? customCategoryIcon = goal.customCategoryIcon ??
        (_customCategoryIconChoices.isNotEmpty
            ? _customCategoryIconChoices.first
            : Icons.category_outlined);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = MaterialLocalizations.of(ctx);
        final suggestions = _customCategoryOptions;
        Future<void> pickStartDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: startDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          );
          if (picked != null) {
            setState(() {
              startDate = picked;
              if (endDate != null && endDate!.isBefore(startDate)) {
                endDate = startDate;
              }
            });
          }
        }

        Future<void> pickEndDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: endDate ?? startDate,
            firstDate: startDate,
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          );
          if (picked != null) {
            setState(() => endDate = picked);
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Goal title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        category = value;
                        if (category != GoalCategory.custom) {
                          customCategoryController.clear();
                          customCategoryError = null;
                          customCategoryIcon =
                              _customCategoryIconChoices.isNotEmpty
                                  ? _customCategoryIconChoices.first
                                  : Icons.category_outlined;
                        } else {
                          customCategoryIcon ??= _customCategoryIconChoices.isNotEmpty
                                  ? _customCategoryIconChoices.first
                                  : Icons.category_outlined;
                        }
                      });
                    }
                  },
                  items: GoalCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label()),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (category == GoalCategory.custom) ...[
                  TextField(
                    controller: customCategoryController,
                    decoration: InputDecoration(
                      labelText: 'Custom category name',
                      hintText: 'e.g. Morning routine',
                      errorText: customCategoryError,
                    ),
                    onChanged: (_) {
                      if (customCategoryError != null) {
                        setState(() => customCategoryError = null);
                      }
                    },
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: suggestions
                          .map(
                            (option) => ActionChip(
                              avatar: option.icon == null
                                  ? null
                                  : Icon(option.icon, size: 18),
                              label: Text(option.name),
                              onPressed: () {
                                setState(() {
                                  customCategoryController.text = option.name;
                                  customCategoryError = null;
                                  if (option.icon != null) {
                                    customCategoryIcon = option.icon;
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Pick an icon',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customCategoryIconChoices
                        .map(
                          (icon) => ChoiceChip(
                            label: Icon(icon, size: 20),
                            selected: customCategoryIcon == icon,
                            onSelected: (_) => setState(() {
                              customCategoryIcon = icon;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: instructions,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Instructions / notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalFrequency>(
                  initialValue: frequency,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => frequency = value);
                    }
                  },
                  items: GoalFrequency.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label()),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: frequency.timesLabel(),
                    helperText:
                        'How many times each ${frequency.shortPeriod()} this goal should happen',
                    errorText: timesError,
                  ),
                  onChanged: (_) {
                    if (timesError != null) {
                      final value =
                          int.tryParse(timesController.text.trim()) ?? 0;
                      if (value > 0) {
                        setState(() => timesError = null);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow_outlined),
                  title: const Text('Start date'),
                  subtitle: Text(l10n.formatMediumDate(startDate)),
                  onTap: pickStartDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('End date'),
                  subtitle: Text(
                    endDate == null
                        ? 'No end date'
                        : l10n.formatMediumDate(endDate!),
                  ),
                  onTap: pickEndDate,
                  trailing: endDate == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear end date',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => endDate = null),
                        ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_outlined),
                  title: const Text('Reminder'),
                  subtitle: Text(reminder.format(ctx)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: reminder,
                    );
                    if (picked != null) {
                      setState(() => reminder = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('Progress ${(progress * 100).round()}%'),
                Slider(
                  value: progress,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  label: '${(progress * 100).round()}%',
                  onChanged: (v) => setState(() {
                    progress = v;
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final parsed =
                          int.tryParse(timesController.text.trim()) ?? 0;
                      if (parsed <= 0) {
                        setState(() => timesError = 'Enter at least 1');
                        return;
                      }
                      String? customName;
                      if (category == GoalCategory.custom) {
                        final name = customCategoryController.text.trim();
                        if (name.isEmpty) {
                          setState(() =>
                              customCategoryError = 'Enter a category name');
                          return;
                        }
                        customName = name;
                      }
                      setState(() {
                        widget.goals[index]
                          ..title = title.text.trim().isEmpty
                              ? widget.goals[index].title
                              : title.text.trim()
                          ..instructions = instructions.text.trim().isEmpty
                              ? null
                              : instructions.text.trim()
                          ..category = category
                          ..customCategoryName = category == GoalCategory.custom
                              ? customName
                              : null
                          ..customCategoryIcon = category == GoalCategory.custom
                              ? customCategoryIcon
                              : null
                          ..frequency = frequency
                          ..timesPerPeriod = parsed
                          ..startDate = startDate
                          ..endDate = endDate
                          ..reminder = reminder
                          ..progress = progress
                          ..importance = importance;
                        if (category == GoalCategory.custom &&
                            (customName?.isNotEmpty ?? false)) {
                          _handleCustomCategoryCreated(
                            customName!,
                            customCategoryIcon,
                          );
                        }
                        _syncCustomCategories();
                      });
                      Navigator.of(ctx).pop();
                      if (_allGoalsComplete) {
                        _triggerOverallCelebrationIfNeeded();
                      } else {
                        _hasShownOverallCelebration = false;
                      }
                    },
                    child: const Text('Save changes'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        widget.goals.removeAt(index);
                        if (!_allGoalsComplete) {
                          _hasShownOverallCelebration = false;
                        }
                        _syncCustomCategories();
                      });
                      if (_allGoalsComplete) {
                        _triggerOverallCelebrationIfNeeded();
                      }
                    },
                    child: const Text('Delete goal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    title.dispose();
    instructions.dispose();
    timesController.dispose();
    customCategoryController.dispose();
  }

  List<Widget> _buildCategorizedGoals(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Map<String, _GoalCategoryGroup> groups = {};
    for (var i = 0; i < widget.goals.length; i++) {
      final goal = widget.goals[i];
      final label = goal.displayCategoryLabel();
      final icon = goal.displayCategoryIcon();
      final color = goal.displayCategoryColor(scheme);
      final isCustom = goal.category == GoalCategory.custom;
      final key = isCustom
          ? 'custom:${label.toLowerCase()}'
          : 'builtin:${goal.category.name}';
      final group = groups.putIfAbsent(
        key,
        () => _GoalCategoryGroup(
          label: label,
          icon: icon,
          color: color,
          isCustom: isCustom,
        ),
      );
      group.indices.add(i);
    }

    final List<_GoalCategoryGroup> orderedGroups = [];
    for (final category in _categoryOrder) {
      final key = 'builtin:${category.name}';
      final group = groups.remove(key);
      if (group != null && group.indices.isNotEmpty) {
        orderedGroups.add(group);
      }
    }
    final customGroups = groups.values
        .where((group) => group.isCustom && group.indices.isNotEmpty)
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    orderedGroups.addAll(customGroups);

    final List<Widget> sections = [];
    for (final group in orderedGroups) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 20));
      }
      final indexes = group.indices;
      final totalProgress = indexes.fold<double>(
        0,
        (sum, idx) => sum + widget.goals[idx].progress,
      );
      final avgProgress =
          ((indexes.isEmpty ? 0.0 : totalProgress / indexes.length)
                  .clamp(0.0, 1.0))
              .toDouble();
      final avgPercent = (avgProgress * 100).round();
      sections.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: group.color.withValues(alpha: 0.4)),
            color: group.color.withValues(alpha: 0.12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(group.icon, color: group.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${group.label} Goals',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: group.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      indexes.length.toString(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: avgProgress,
                backgroundColor: group.color.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 4),
              Text(
                '$avgPercent% complete across ${indexes.length} goals',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
      sections.add(const SizedBox(height: 12));

      for (var i = 0; i < indexes.length; i++) {
        final goal = widget.goals[indexes[i]];
        sections.add(
          _buildGoalCardWidget(
            goal,
            isLast: i == indexes.length - 1,
          ),
        );
      }
    }
    return sections;
  }
}

class _DietPlanSection extends StatefulWidget {
  const _DietPlanSection({
    required this.menu,
    required this.selections,
    required this.deliveryWindows,
    required this.completed,
    required this.notes,
    required this.onSelectMeal,
    required this.onChangeWindow,
    required this.onToggleCompleted,
    required this.onNotesChanged,
  });

  final Map<MealSlot, List<MealOption>> menu;
  final Map<MealSlot, int> selections;
  final Map<MealSlot, TimeOfDay> deliveryWindows;
  final Set<MealSlot> completed;
  final String notes;
  final void Function(MealSlot slot, int index) onSelectMeal;
  final void Function(MealSlot slot, TimeOfDay time) onChangeWindow;
  final void Function(MealSlot slot, bool value) onToggleCompleted;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_DietPlanSection> createState() => _DietPlanSectionState();
}

class _DietPlanSectionState extends State<_DietPlanSection> {
  late final TextEditingController _notesController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant _DietPlanSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes &&
        widget.notes != _notesController.text) {
      _notesController.value = TextEditingValue(
        text: widget.notes,
        selection: TextSelection.collapsed(offset: widget.notes.length),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  double _planProgress() {
    final total = MealSlot.values.length;
    if (total == 0) return 0;
    return widget.completed.length / total;
  }

  int _totalCalories() {
    var total = 0;
    for (final slot in MealSlot.values) {
      final options = widget.menu[slot];
      if (options == null || options.isEmpty) continue;
      final index = widget.selections[slot] ?? 0;
      final safeIndex = index.clamp(0, options.length - 1).toInt();
      total += options[safeIndex].calories;
    }
    return total;
  }

  Future<void> _pickMeal(MealSlot slot) async {
    final options = widget.menu[slot] ?? [];
    if (options.isEmpty) return;
    final selected = widget.selections[slot] ?? 0;
    final result = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose ${slot.label.toLowerCase()}',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...List.generate(options.length, (index) {
                  final option = options[index];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index == options.length - 1 ? 0 : 12),
                    child: _MealOptionTile(
                      option: option,
                      selected: index == selected,
                      onTap: () => Navigator.of(ctx).pop(index),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      widget.onSelectMeal(slot, result);
      setState(() {});
    }
  }

  Future<void> _pickWindow(MealSlot slot) async {
    final fallback =
        kDefaultMealWindows[slot] ?? const TimeOfDay(hour: 12, minute: 0);
    final initial = widget.deliveryWindows[slot] ?? fallback;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      widget.onChangeWindow(slot, picked);
      setState(() {});
    }
  }

  String _formatTime(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _planProgress().clamp(0.0, 1.0);
    final completed = widget.completed.length;
    final totalMeals = MealSlot.values.length;
    final calories = _totalCalories();
    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              toggled: _expanded,
              label: 'Daily nutrition plan',
              hint: _expanded
                  ? 'Tap to collapse your nutrition plan'
                  : 'Tap to expand your nutrition plan',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleExpanded,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme.colorScheme.tertiary.withValues(alpha: 0.16),
                      child: const Icon(Icons.restaurant_menu),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily nutrition plan',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 6),
                          Text(
                            '$completed of $totalMeals meals checked off · $calories kcal planned',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  ...MealSlot.values.map((slot) {
                    final isLast = slot == MealSlot.values.last;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: _buildMealCard(context, slot),
                    );
                  }),
                  const SizedBox(height: 4),
                  Text(
                    'Plan notes',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: widget.onNotesChanged,
                    decoration: const InputDecoration(
                      hintText: 'Add reminders like hydration or supplements…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, MealSlot slot) {
    final theme = Theme.of(context);
    final options = widget.menu[slot] ?? const <MealOption>[];
    final rawIndex = widget.selections[slot] ?? 0;
    final maxIndex = options.isEmpty ? 0 : options.length - 1;
    final currentIndex = rawIndex.clamp(0, maxIndex).toInt();
    final option = options.isEmpty ? null : options[currentIndex];
    final isCompleted = widget.completed.contains(slot);
    final time = widget.deliveryWindows[slot] ??
        kDefaultMealWindows[slot] ??
        const TimeOfDay(hour: 12, minute: 0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slot.color.withValues(alpha: isCompleted ? 0.55 : 0.28),
          width: isCompleted ? 1.6 : 1.1,
        ),
        color: slot.color.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (value) {
                  widget.onToggleCompleted(slot, value ?? false);
                  setState(() {});
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (option != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.title,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Adjust meal',
                onPressed: options.length <= 1 ? null : () => _pickMeal(slot),
                icon: const Icon(Icons.restaurant_menu_outlined),
              ),
            ],
          ),
          if (option != null) ...[
            const SizedBox(height: 6),
            Text(option.description),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_formatTime(time)),
                onPressed: () => _pickWindow(slot),
              ),
              if (option != null)
                Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 18),
                  label: Text('${option.calories} kcal'),
                ),
              if (option != null)
                ...option.tags.map((tag) => Chip(label: Text(tag))),
            ],
          ),
          if (option?.note != null && option!.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              option.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({
    required this.goal,
    required this.onCheckIn,
    required this.onEdit,
    required this.onDelete,
    required this.onImportanceChanged,
    this.onMoveUp,
    this.onMoveDown,
  });

  final Goal goal;
  final VoidCallback onCheckIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<GoalImportance> onImportanceChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  PopupMenuButton<GoalImportance> _importanceMenu({
    required GoalImportance selected,
    required Widget child,
  }) {
    return PopupMenuButton<GoalImportance>(
      tooltip: 'Set importance',
      initialValue: selected,
      onSelected: widget.onImportanceChanged,
      itemBuilder: (ctx) => GoalImportance.values
          .map(
            (level) => PopupMenuItem(
              value: level,
              child: Row(
                children: [
                  Icon(
                    level.icon(),
                    size: 18,
                    color: level == selected
                        ? Theme.of(ctx).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(level.label()),
                ],
              ),
            ),
          )
          .toList(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = widget.goal;
    final l10n = MaterialLocalizations.of(context);
    final percent = (goal.progress * 100).round();
    final categoryColor = goal.displayCategoryColor(scheme);
    final categoryLabel = goal.displayCategoryLabel();
    final categoryIcon = goal.displayCategoryIcon();
    final importance = goal.importance;
    final importanceColor = importance.color(scheme);
    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    toggled: _expanded,
                    label: goal.title,
                    hint: _expanded
                        ? 'Collapse goal details'
                        : 'Expand to view goal details',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleExpanded,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                categoryColor.withValues(alpha: 0.18),
                            child: Icon(
                              categoryIcon,
                              size: 20,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categoryLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$percent% complete',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                _importanceMenu(
                                  selected: importance,
                                  child: Text(
                                    'Importance: ${importance.label()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.onMoveUp != null ||
                              widget.onMoveDown != null) ...[
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  tooltip: 'Move goal up',
                                  onPressed: widget.onMoveUp,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minHeight: 32,
                                    minWidth: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  tooltip: 'Move goal down',
                                  onPressed: widget.onMoveDown,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minHeight: 32,
                                    minWidth: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AnimatedRotation(
                              turns: _expanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              child: const Icon(Icons.keyboard_arrow_down),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: goal.progress),
            const SizedBox(height: 6),
            Text('$percent% complete'),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar: Icon(
                          categoryIcon,
                          size: 18,
                          color: categoryColor,
                        ),
                        label: Text(categoryLabel),
                        backgroundColor: categoryColor.withValues(alpha: 0.12),
                      ),
                      Chip(
                        avatar: const Icon(Icons.repeat, size: 18),
                        label: Text(_frequencySummary(context)),
                      ),
                      Chip(
                        avatar: const Icon(Icons.event_outlined, size: 18),
                        label: Text(_dateRangeLabel(l10n)),
                      ),
                      Chip(
                        avatar: const Icon(Icons.alarm_outlined, size: 18),
                        label:
                            Text('Reminder ${goal.reminder.format(context)}'),
                      ),
                      _importanceMenu(
                        selected: importance,
                        child: Chip(
                          avatar: Icon(
                            importance.icon(),
                            size: 18,
                            color: importanceColor,
                          ),
                          label: Text('Importance: ${importance.label()}'),
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          backgroundColor:
                              importanceColor.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                  if ((goal.instructions ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      goal.instructions!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit goal'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOut,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onCheckIn,
                icon: const Icon(Icons.check_circle),
                label: const Text('Check in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencySummary(BuildContext context) {
    final times = widget.goal.timesPerPeriod;
    final unit = times == 1 ? 'time' : 'times';
    return '$times $unit per ${widget.goal.frequency.shortPeriod()}';
  }

  String _dateRangeLabel(MaterialLocalizations l10n) {
    final start = l10n.formatMediumDate(widget.goal.startDate);
    final end = widget.goal.endDate == null
        ? 'Ongoing'
        : l10n.formatMediumDate(widget.goal.endDate!);
    return '$start - $end';
  }
}

class GoalCompletionCelebration extends StatefulWidget {
  const GoalCompletionCelebration({super.key, required this.goal});

  final Goal goal;

  @override
  State<GoalCompletionCelebration> createState() =>
      _GoalCompletionCelebrationState();
}

class _CategorySummary {
  _CategorySummary({required this.label, required this.icon});

  final String label;
  final IconData icon;
  int count = 0;
}

class _GoalCategoryGroup {
  _GoalCategoryGroup({
    required this.label,
    required this.icon,
    required this.color,
    required this.isCustom,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isCustom;
  final List<int> indices = <int>[];
}

class _GoalCompletionCelebrationState extends State<GoalCompletionCelebration>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 5));
  late final AnimationController _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _scale = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    _fadeController.forward();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.goal;
    final categoryColor = goal.displayCategoryColor(theme.colorScheme);
    const onColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withValues(alpha: 0.95),
                  theme.colorScheme.secondary.withValues(alpha: 0.85),
                  theme.colorScheme.surfaceTint.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 120,
                  maxBlastForce: 16,
                  minBlastForce: 6,
                  emissionFrequency: 0.02,
                  gravity: 0.2,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi,
                  emissionFrequency: 0.016,
                  numberOfParticles: 60,
                  maxBlastForce: 10,
                  minBlastForce: 4,
                  gravity: 0.15,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: onColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeController,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: onColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: onColor.withValues(alpha: 0.45),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 32,
                              offset: const Offset(0, 26),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: onColor.withValues(alpha: 0.28),
                                border: Border.all(
                                  color: onColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(
                                goal.displayCategoryIcon(),
                                color: onColor,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Milestone reached!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: onColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              goal.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: onColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'You just completed your ${goal.displayCategoryLabel().toLowerCase()} goal.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: onColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeController,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: onColor,
                          foregroundColor: categoryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Keep it going'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoalsVictoryOverlay extends StatefulWidget {
  const GoalsVictoryOverlay({super.key, required this.goals});

  final List<Goal> goals;

  @override
  State<GoalsVictoryOverlay> createState() => _GoalsVictoryOverlayState();
}

class _GoalsVictoryOverlayState extends State<GoalsVictoryOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 6));
  late final AnimationController _heroController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 640));
  late final Animation<double> _heroScale =
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    _heroController.forward();
    _fadeController.forward();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final total = widget.goals.length;
    final categorySummaries = <String, _CategorySummary>{};
    for (final goal in widget.goals) {
      final label = goal.displayCategoryLabel();
      final icon = goal.displayCategoryIcon();
      final summary = categorySummaries.putIfAbsent(
        label,
        () => _CategorySummary(label: label, icon: icon),
      );
      summary.count += 1;
    }
    final gradientColors = isDark
        ? [
            cs.surface.withValues(alpha: 0.96),
            cs.surfaceContainerHighest.withValues(alpha: 0.94),
            cs.primary.withValues(alpha: 0.7),
          ]
        : [
            cs.primary.withValues(alpha: 0.92),
            cs.secondary.withValues(alpha: 0.88),
            cs.surfaceTint.withValues(alpha: 0.86),
          ];
    final overlayPrimaryColor = isDark ? cs.onSurface : Colors.white;
    final overlaySecondaryColor = isDark
        ? cs.onSurface.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    final closeIconColor = isDark ? cs.onSurface : Colors.white;
    final heroOuterColor = isDark
        ? cs.primaryContainer.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.2);
    final heroBorderColor = isDark
        ? cs.primaryContainer.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.45);
    final heroInnerColor = isDark ? cs.primaryContainer : Colors.white;
    final heroIconColor = isDark ? cs.onPrimaryContainer : cs.secondary;
    final cardBackgroundColor = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.94);
    final cardBorderColor = isDark
        ? cs.outline.withValues(alpha: 0.35)
        : cs.secondary.withValues(alpha: 0.25);
    final accent = cs.secondary;
    final onCard = isDark ? cs.onSurface : Colors.black.withValues(alpha: 0.78);
    final chipBackgroundColor =
        cs.secondaryContainer.withValues(alpha: isDark ? 0.45 : 0.2);
    final chipBorderColor = (isDark ? cs.onSecondaryContainer : cs.secondary)
        .withValues(alpha: isDark ? 0.3 : 0.22);
    final chipIconColor = isDark ? cs.onSecondaryContainer : accent;
    final chipLabelColor = isDark ? cs.onSecondaryContainer : onCard;
    final buttonBackground = isDark ? cs.primary : Colors.white;
    final buttonForeground = isDark ? cs.onPrimary : cs.secondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 150,
                  maxBlastForce: 18,
                  minBlastForce: 6,
                  emissionFrequency: 0.018,
                  gravity: 0.22,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi,
                  emissionFrequency: 0.015,
                  numberOfParticles: 70,
                  maxBlastForce: 12,
                  minBlastForce: 5,
                  gravity: 0.16,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: closeIconColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _heroScale,
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: heroOuterColor,
                              border: Border.all(
                                color: heroBorderColor,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 28,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: heroInnerColor,
                              ),
                              child: Icon(
                                Icons.workspace_premium_outlined,
                                size: 68,
                                color: heroIconColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Amazing! All goals complete',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: overlayPrimaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You finished all $total goals. Keep the momentum going!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: overlaySecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                            child: Builder(
                              builder: (context) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: cardBackgroundColor,
                                    border: Border.all(
                                      color: cardBorderColor,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _CelebrationStat(
                                        icon: Icons.flag,
                                        label: '$total goals completed',
                                        color: accent,
                                      ),
                                      const SizedBox(height: 14),
                                      if (categorySummaries.isNotEmpty)
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: categorySummaries.values
                                              .map(
                                                (summary) => Chip(
                                                  avatar: Icon(
                                                    summary.icon,
                                                    size: 18,
                                                    color: chipIconColor,
                                                  ),
                                                  label: Text(
                                                    '${summary.label} · ${summary.count}',
                                                  ),
                                                  labelStyle: theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                    color: chipLabelColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  backgroundColor:
                                                      chipBackgroundColor,
                                                  side: BorderSide(
                                                    color: chipBorderColor,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeController,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: buttonBackground,
                          foregroundColor: buttonForeground,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Keep moving forward'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationStat extends StatelessWidget {
  const _CelebrationStat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomCategoryOption {
  const _CustomCategoryOption({required this.name, this.icon});

  final String name;
  final IconData? icon;
}

const List<IconData> _customCategoryIconChoices = [
  Icons.category_outlined,
  Icons.star_outline,
  Icons.favorite_outline,
  Icons.flag_outlined,
  Icons.self_improvement_outlined,
  Icons.local_florist_outlined,
  Icons.nightlight_round,
  Icons.health_and_safety_outlined,
  Icons.waves_outlined,
];

class _GoalFormDialog extends StatefulWidget {
  const _GoalFormDialog({
    required this.customCategories,
    required this.onRegisterCustomCategory,
    required this.initialCategory,
    this.initialCustomCategoryName,
    this.initialCustomCategoryIcon,
  });

  final List<_CustomCategoryOption> customCategories;
  final void Function(String name, IconData? icon) onRegisterCustomCategory;
  final GoalCategory initialCategory;
  final String? initialCustomCategoryName;
  final IconData? initialCustomCategoryIcon;
  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  final _timesPerPeriodController = TextEditingController(text: '1');
  late final TextEditingController _customCategoryController;
  String? _timesError;
  String? _customCategoryError;
  late GoalCategory category;
  IconData? _customCategoryIcon;
  GoalFrequency freq = GoalFrequency.daily;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  DateTime startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? endDate;
  GoalImportance importance = GoalImportance.medium;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    _customCategoryController = TextEditingController(
      text: widget.initialCustomCategoryName ?? '',
    );
    _customCategoryIcon = widget.initialCustomCategoryIcon ??
        (_customCategoryIconChoices.isNotEmpty
            ? _customCategoryIconChoices.first
            : Icons.category_outlined);
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    _timesPerPeriodController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate)) {
          endDate = startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  void _selectSuggestedCategory(String name) {
    setState(() {
      _customCategoryController.text = name;
      _customCategoryError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add Goal'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tips: keep each goal specific, measurable, and realistic. '
                'Pair it with a timeframe and the number of times you plan to do it.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Goal title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    category = value;
                    if (category != GoalCategory.custom) {
                      _customCategoryController.clear();
                      _customCategoryError = null;
                      _customCategoryIcon =
                          _customCategoryIconChoices.isNotEmpty
                              ? _customCategoryIconChoices.first
                              : Icons.category_outlined;
                    } else {
                      _customCategoryIcon ??= _customCategoryIconChoices.isNotEmpty
                              ? _customCategoryIconChoices.first
                              : Icons.category_outlined;
                    }
                  });
                }
              },
              items: GoalCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label()),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (category == GoalCategory.custom) ...[
              TextField(
                controller: _customCategoryController,
                decoration: InputDecoration(
                  labelText: 'Custom category name',
                  hintText: 'e.g. Morning routine',
                  errorText: _customCategoryError,
                ),
                onChanged: (_) {
                  if (_customCategoryError != null) {
                    setState(() => _customCategoryError = null);
                  }
                },
              ),
              if (widget.customCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.customCategories
                      .map(
                        (option) => ActionChip(
                          avatar: option.icon == null
                              ? null
                              : Icon(option.icon, size: 18),
                          label: Text(option.name),
                          onPressed: () {
                            _selectSuggestedCategory(option.name);
                            if (option.icon != null) {
                              setState(() => _customCategoryIcon = option.icon);
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Pick an icon',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customCategoryIconChoices
                    .map(
                      (icon) => ChoiceChip(
                        label: Icon(icon, size: 20),
                        selected: _customCategoryIcon == icon,
                        onSelected: (_) => setState(() {
                          _customCategoryIcon = icon;
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<GoalImportance>(
              initialValue: importance,
              decoration: const InputDecoration(labelText: 'Importance'),
              onChanged: (value) {
                if (value != null) {
                  setState(() => importance = value);
                }
              },
              items: GoalImportance.values
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Row(
                        children: [
                          Icon(level.icon(), size: 18),
                          const SizedBox(width: 8),
                          Text(level.label()),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructions,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instructions / notes',
                hintText: 'Add steps, supports, or reminders for this goal',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalFrequency>(
              initialValue: freq,
              onChanged: (v) {
                if (v != null) {
                  setState(() => freq = v);
                }
              },
              items: GoalFrequency.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label()),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timesPerPeriodController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: freq.timesLabel(),
                helperText:
                    'How many times each ${freq.shortPeriod()} you plan to do this',
                errorText: _timesError,
              ),
              onChanged: (_) {
                if (_timesError != null) {
                  final value = int.tryParse(
                    _timesPerPeriodController.text.trim(),
                  );
                  if (value != null && value > 0) {
                    setState(() => _timesError = null);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text('Start date'),
              subtitle: Text(l10n.formatMediumDate(startDate)),
              onTap: _pickStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('End date'),
              subtitle: Text(
                endDate == null
                    ? 'No end date'
                    : l10n.formatMediumDate(endDate!),
              ),
              onTap: _pickEndDate,
              trailing: endDate == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear end date',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => endDate = null),
                    ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm_outlined),
              title: const Text('Reminder'),
              subtitle: Text(time.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  setState(() => time = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final raw = _timesPerPeriodController.text.trim();
            final parsed = int.tryParse(raw) ?? 0;
            if (parsed <= 0) {
              setState(() => _timesError = 'Enter at least 1');
              return;
            }
            String? customName;
            if (category == GoalCategory.custom) {
              final name = _customCategoryController.text.trim();
              if (name.isEmpty) {
                setState(() => _customCategoryError = 'Enter a category name');
                return;
              }
              customName = name;
              widget.onRegisterCustomCategory(name, _customCategoryIcon);
            }
            Navigator.pop(
              context,
              _GoalFormResult(
                title: _title.text,
                instructions: _instructions.text,
                category: category,
                customCategoryName: customName,
                customCategoryIcon: category == GoalCategory.custom
                    ? _customCategoryIcon
                    : null,
                frequency: freq,
                timesPerPeriod: parsed,
                startDate: startDate,
                endDate: endDate,
                reminder: time,
                importance: importance,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GoalFormResult {
  _GoalFormResult({
    required this.title,
    required this.instructions,
    required this.category,
    this.customCategoryName,
    this.customCategoryIcon,
    required this.frequency,
    required this.timesPerPeriod,
    required this.startDate,
    required this.endDate,
    required this.reminder,
    required this.importance,
  });
  final String title;
  final String instructions;
  final GoalCategory category;
  final String? customCategoryName;
  final IconData? customCategoryIcon;
  final GoalFrequency frequency;
  final int timesPerPeriod;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay reminder;
  final GoalImportance importance;
}
