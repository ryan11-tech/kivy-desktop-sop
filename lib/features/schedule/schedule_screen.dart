import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

// ── Simple data models (Phase 1 — local only) ─────────────────────────────────

class ShiftDef {
  const ShiftDef({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final Color color;
}

class StaffMember {
  const StaffMember({required this.id, required this.name});
  final String id;
  final String name;
}

class ShiftEntry {
  ShiftEntry({required this.shiftId, List<String>? staffIds})
    : staffIds = staffIds ?? [];
  final String shiftId;
  final List<String> staffIds;
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.name,
    required this.days,
    List<String>? assignedStaff,
  }) : assignedStaff = assignedStaff ?? [];
  final String id;
  final String name;
  final List<String> days;
  final List<String> assignedStaff;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayFull = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
  'Sat': 'Saturday',
  'Sun': 'Sunday',
};

// ── ScheduleScreen ────────────────────────────────────────────────────────────

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    this.isAdmin = false,
    this.embedded = false,
    super.key,
  });
  final bool isAdmin;
  final bool embedded;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _activeDay = 'Mon';
  int _tabIndex = 0; // 0=Schedule, 1=Tasks, 2=Manage

  // Local state (Phase 1)
  final List<ShiftDef> _shifts = [
    const ShiftDef(
      id: 'morning',
      name: 'Morning Shift',
      startTime: '07:00',
      endTime: '13:00',
      color: AppColors.gold,
    ),
    const ShiftDef(
      id: 'evening',
      name: 'Evening Shift',
      startTime: '13:00',
      endTime: '20:00',
      color: AppColors.cold,
    ),
  ];

  final List<StaffMember> _staff = [
    const StaffMember(id: 's1', name: 'Staff A'),
    const StaffMember(id: 's2', name: 'Staff B'),
  ];

  final Map<String, List<ShiftEntry>> _schedule = {
    for (final d in _days) d: [],
  };

  final List<TaskItem> _tasks = [];

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        const Divider(height: 1, color: AppColors.surfaceHigh),
        _buildTabBar(),
        const Divider(height: 1, color: AppColors.surfaceHigh),
        Expanded(
          child:
              _tabIndex == 0
                  ? _buildScheduleTab()
                  : _tabIndex == 1
                  ? _buildTasksTab()
                  : _buildManageTab(),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: AppColors.background, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Staff Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isAdmin ? AppColors.primary : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.isAdmin ? 'ADMIN' : 'STAFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = ['Schedule', 'Tasks', if (widget.isAdmin) 'Manage'];
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children:
            tabs.asMap().entries.map((e) {
              final idx = e.key;
              final label = e.value;
              final isSelected = idx == _tabIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = idx),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ── Schedule Tab ─────────────────────────────────────────────────────────

  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // Day selector
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                _days.map((day) {
                  final isSelected = day == _activeDay;
                  return GestureDetector(
                    onTap: () => setState(() => _activeDay = day),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white38,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Day full name
        Text(
          _dayFull[_activeDay] ?? _activeDay,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Shift entries
        ...(_schedule[_activeDay] ?? []).asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final shift = _shifts.firstWhere(
            (s) => s.id == entry.shiftId,
            orElse: () => _shifts.first,
          );
          return _ShiftCard(
            entry: entry,
            shift: shift,
            staff: _staff,
            isAdmin: widget.isAdmin,
            onDelete:
                () => setState(() {
                  _schedule[_activeDay]!.removeAt(idx);
                }),
            onAssign:
                (staffIds) => setState(() {
                  entry.staffIds
                    ..clear()
                    ..addAll(staffIds);
                }),
          );
        }),

        if ((_schedule[_activeDay] ?? []).isEmpty)
          const _EmptyState(
            title: 'No shifts assigned',
            subtitle: 'Tap "+ Add Shift" below to assign one.',
          ),

        if (widget.isAdmin) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddShiftToDay(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text('Add Shift to ${_dayFull[_activeDay]}'),
          ),
        ],
      ],
    );
  }

  // ── Tasks Tab ────────────────────────────────────────────────────────────

  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        if (_tasks.isEmpty)
          const _EmptyState(
            title: 'No tasks yet',
            subtitle: 'Admin can add tasks from this tab.',
          )
        else
          ..._tasks.map(
            (task) => _TaskCard(
              task: task,
              staff: _staff,
              isAdmin: widget.isAdmin,
              onDelete:
                  () => setState(
                    () => _tasks.removeWhere((t) => t.id == task.id),
                  ),
              onAssign:
                  (staffIds) => setState(() {
                    task.assignedStaff
                      ..clear()
                      ..addAll(staffIds);
                  }),
            ),
          ),

        if (widget.isAdmin) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddTask(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add New Task'),
          ),
        ],
      ],
    );
  }

  // ── Manage Tab ───────────────────────────────────────────────────────────

  Widget _buildManageTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        const _SectionLabel(text: 'SHIFT TYPES'),
        const SizedBox(height: 8),

        if (_shifts.isEmpty)
          const Text(
            'No shift types yet.',
            style: TextStyle(color: Colors.white38),
          ),

        ..._shifts.map(
          (shift) => _ShiftDefRow(
            shift: shift,
            onDelete:
                () => setState(
                  () => _shifts.removeWhere((s) => s.id == shift.id),
                ),
          ),
        ),

        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showAddShiftDef(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Shift Type'),
        ),

        const SizedBox(height: 24),
        const _SectionLabel(text: 'STAFF MEMBERS'),
        const SizedBox(height: 8),

        if (_staff.isEmpty)
          const Text(
            'No staff members yet.',
            style: TextStyle(color: Colors.white38),
          ),

        ..._staff.map(
          (member) => _StaffRow(
            member: member,
            onDelete:
                () => setState(
                  () => _staff.removeWhere((s) => s.id == member.id),
                ),
          ),
        ),

        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showAddStaff(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Staff Member'),
        ),

        const SizedBox(height: 24),
        const _SectionLabel(text: 'DANGER ZONE'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _confirmClearWeek(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.delete_sweep),
          label: const Text("Clear This Week's Schedule"),
        ),
      ],
    );
  }

  // ── Popups ───────────────────────────────────────────────────────────────

  void _showAddShiftDef(BuildContext context) {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '07:00');
    final endCtrl = TextEditingController(text: '13:00');
    final colorCtrl = TextEditingController(text: '#C9A84C');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Shift Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: nameCtrl,
                  hint: 'e.g. Morning Shift',
                  label: 'Name',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: startCtrl,
                        hint: '07:00',
                        label: 'Start',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InputField(
                        controller: endCtrl,
                        hint: '13:00',
                        label: 'End',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InputField(
                  controller: colorCtrl,
                  hint: '#C9A84C',
                  label: 'Color (hex)',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final hex = colorCtrl.text.trim();
                          setState(() {
                            _shifts.add(
                              ShiftDef(
                                id:
                                    'shift_${DateTime.now().millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                                startTime: startCtrl.text.trim(),
                                endTime: endCtrl.text.trim(),
                                color: _parseColor(hex),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white38,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showAddStaff(BuildContext context) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Staff Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: nameCtrl,
                  hint: 'e.g. Ko Aung',
                  label: 'Name',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setState(() {
                            _staff.add(
                              StaffMember(
                                id:
                                    'staff_${DateTime.now().millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white38,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showAddShiftToDay(BuildContext context) {
    if (_shifts.isEmpty) {
      _showMsg(
        context,
        'No shift types yet.\nGo to Manage tab to add shifts first.',
      );
      return;
    }
    String selectedId = _shifts.first.id;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Shift to ${_dayFull[_activeDay]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._shifts.map((shift) {
                        final isSel = shift.id == selectedId;
                        return GestureDetector(
                          onTap: () => setLocal(() => selectedId = shift.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSel ? shift.color : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${shift.name}  (${shift.startTime}–${shift.endTime})',
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white60,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _schedule[_activeDay]!.add(
                                    ShiftEntry(shiftId: selectedId),
                                  );
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white38,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showAddTask(BuildContext context) {
    final nameCtrl = TextEditingController();
    final selectedDays = <String>[];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: nameCtrl,
                        hint: 'e.g. Clean equipment',
                        label: 'Task Name',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Days (leave blank = every day)',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            _days.map((d) {
                              final isSel = selectedDays.contains(d);
                              return GestureDetector(
                                onTap:
                                    () => setLocal(() {
                                      if (isSel) {
                                        selectedDays.remove(d);
                                      } else {
                                        selectedDays.add(d);
                                      }
                                    }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSel
                                            ? AppColors.primary
                                            : AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      color:
                                          isSel ? Colors.white : Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty) return;
                                setState(() {
                                  _tasks.add(
                                    TaskItem(
                                      id:
                                          'task_${DateTime.now().millisecondsSinceEpoch}',
                                      name: nameCtrl.text.trim(),
                                      days: List.from(selectedDays),
                                    ),
                                  );
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white38,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _confirmClearWeek(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Clear Week',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Clear all shifts for this week?\nThis cannot be undone.',
              style: TextStyle(color: Colors.white60),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    for (final d in _days) {
                      _schedule[d]!.clear();
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _showMsg(BuildContext context, String msg) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            content: Text(msg, style: const TextStyle(color: Colors.white70)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.gold;
    }
  }
}

// ── Shift Card ────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.entry,
    required this.shift,
    required this.staff,
    required this.isAdmin,
    required this.onDelete,
    required this.onAssign,
  });

  final ShiftEntry entry;
  final ShiftDef shift;
  final List<StaffMember> staff;
  final bool isAdmin;
  final VoidCallback onDelete;
  final void Function(List<String>) onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: shift.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shift.name,
                    style: TextStyle(
                      color: shift.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${shift.startTime} – ${shift.endTime}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceHigh),

          // Staff list
          if (entry.staffIds.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No staff assigned',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            )
          else
            ...entry.staffIds.map((sid) {
              final member = staff.firstWhere(
                (s) => s.id == sid,
                orElse: () => StaffMember(id: sid, name: sid),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          if (isAdmin)
            TextButton.icon(
              onPressed:
                  () => _showAssignStaff(context, entry, staff, onAssign),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Assign Staff'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAssignStaff(
    BuildContext context,
    ShiftEntry entry,
    List<StaffMember> staff,
    void Function(List<String>) onAssign,
  ) {
    if (staff.isEmpty) {
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              content: const Text(
                'No staff yet.\nGo to Manage tab first.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final selected = List<String>.from(entry.staffIds);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...staff.map((member) {
                        final isSel = selected.contains(member.id);
                        return GestureDetector(
                          onTap:
                              () => setLocal(() {
                                if (isSel) {
                                  selected.remove(member.id);
                                } else {
                                  selected.add(member.id);
                                }
                              }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSel
                                      ? AppColors.primary
                                      : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isSel ? Colors.white : Colors.white38,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    color:
                                        isSel ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                onAssign(selected);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white38,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.staff,
    required this.isAdmin,
    required this.onDelete,
    required this.onAssign,
  });

  final TaskItem task;
  final List<StaffMember> staff;
  final bool isAdmin;
  final VoidCallback onDelete;
  final void Function(List<String>) onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  task.days.isEmpty ? 'Every day' : task.days.join('  '),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceHigh),
          if (task.assignedStaff.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No staff assigned',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            )
          else
            ...task.assignedStaff.map((sid) {
              final member = staff.firstWhere(
                (s) => s.id == sid,
                orElse: () => StaffMember(id: sid, name: sid),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (isAdmin)
            TextButton.icon(
              onPressed:
                  () => _showAssignStaffTask(context, task, staff, onAssign),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Assign Staff'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAssignStaffTask(
    BuildContext context,
    TaskItem task,
    List<StaffMember> staff,
    void Function(List<String>) onAssign,
  ) {
    final selected = List<String>.from(task.assignedStaff);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Assign to: ${task.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...staff.map((member) {
                        final isSel = selected.contains(member.id);
                        return GestureDetector(
                          onTap:
                              () => setLocal(() {
                                if (isSel) {
                                  selected.remove(member.id);
                                } else {
                                  selected.add(member.id);
                                }
                              }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSel
                                      ? AppColors.primary
                                      : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isSel ? Colors.white : Colors.white38,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    color:
                                        isSel ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                onAssign(selected);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white38,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

// ── Shift Def Row ─────────────────────────────────────────────────────────────

class _ShiftDefRow extends StatelessWidget {
  const _ShiftDefRow({required this.shift, required this.onDelete});

  final ShiftDef shift;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: shift.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shift.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${shift.startTime} – ${shift.endTime}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staff Row ─────────────────────────────────────────────────────────────────

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member, required this.onDelete});

  final StaffMember member;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.label,
  });

  final TextEditingController controller;
  final String hint;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
