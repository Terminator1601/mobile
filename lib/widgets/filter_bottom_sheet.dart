import 'package:flutter/material.dart';

import '../main.dart';
import 'glass_card.dart';

class EventFilters {
  final double radius;
  final String? category;
  final String timeFilter;

  const EventFilters({
    this.radius = 50000,
    this.category,
    this.timeFilter = 'all',
  });

  EventFilters copyWith({
    double? radius,
    String? category,
    String? timeFilter,
    bool clearCategory = false,
  }) {
    return EventFilters(
      radius: radius ?? this.radius,
      category: clearCategory ? null : (category ?? this.category),
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }
}

const _categories = [
  'All',
  'Party',
  'Music',
  'Art',
  'Food',
  'Sports',
  'Wellness',
  'Networking'
];

const _timeFilters = [
  ('all', 'All'),
  ('live', 'Live Now'),
  ('upcoming', 'Upcoming'),
  ('today', 'Today'),
  ('this_week', 'This Week'),
];

class FilterBottomSheet extends StatefulWidget {
  final EventFilters initialFilters;
  final void Function(EventFilters filters) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required EventFilters initialFilters,
    required void Function(EventFilters filters) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _radius;
  late String? _category;
  late String _timeFilter;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialFilters.radius;
    _category = widget.initialFilters.category;
    _timeFilter = widget.initialFilters.timeFilter;
  }

  void _reset() {
    setState(() {
      _radius = 50000;
      _category = null;
      _timeFilter = 'all';
    });
  }

  void _apply() {
    widget.onApply(EventFilters(
      radius: _radius,
      category: _category,
      timeFilter: _timeFilter,
    ));
    Navigator.of(context).pop();
  }

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).round()} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Distance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('5 km', style: TextStyle(fontSize: 12, color: muted)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: kGradientPurple,
                        inactiveTrackColor: muted.withValues(alpha: 0.2),
                        thumbColor: kGradientPurple,
                        overlayColor: kGradientPurple.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _radius,
                        min: 5000,
                        max: 100000,
                        divisions: 19,
                        label: _formatRadius(_radius),
                        onChanged: (value) => setState(() => _radius = value),
                      ),
                    ),
                  ),
                  Text('100 km', style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  borderRadius: 12,
                  child: Text(
                    _formatRadius(_radius),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected =
                      (cat == 'All' && _category == null) ||
                      (_category?.toLowerCase() == cat.toLowerCase());
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _category = cat == 'All' ? null : cat.toLowerCase();
                      });
                    },
                    selectedColor: kGradientPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : muted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeFilters.map((filter) {
                  final (id, label) = filter;
                  final isSelected = _timeFilter == id;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _timeFilter = id);
                    },
                    selectedColor: kGradientPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : muted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: kGradientPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
