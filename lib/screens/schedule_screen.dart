import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../services/notification_service.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedActivity = 'Scanning';

  final List<Map<String, dynamic>> _activities = [
    {'name': 'Scanning', 'icon': Icons.qr_code_scanner_rounded, 'color': Colors.blue, 'desc': 'Use AI to check for diseases early.'},
    {'name': 'Watering', 'icon': Icons.water_drop_rounded, 'color': Colors.cyan, 'desc': 'Maintain consistent soil moisture.'},
    {'name': 'Pruning', 'icon': Icons.content_cut_rounded, 'color': Colors.orange, 'desc': 'Remove damaged or infected parts.'},
    {'name': 'Fertilizing', 'icon': Icons.grain_rounded, 'color': Colors.purple, 'desc': 'Apply nitrogen-rich nutrients.'},
    {'name': 'Pest Control', 'icon': Icons.bug_report_rounded, 'color': Colors.red, 'desc': 'Monitor for caterpillars & aphids.'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateSelectedActivityToSuggestion(_focusedDay);
  }

  void _updateSelectedActivityToSuggestion(DateTime day) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final suggestion = provider.getSuggestedActivity(day);
    for (var act in _activities) {
      if (suggestion.toLowerCase().contains(act['name'].toLowerCase())) {
        setState(() => _selectedActivity = act['name']);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, provider, colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSmartHero(provider, colorScheme),
                  const SizedBox(height: 32),
                  _buildSectionLabel('SELECT DATE & TASK'),
                  const SizedBox(height: 16),
                  _buildCalendarCard(colorScheme, isDark),
                  const SizedBox(height: 24),
                  _buildActivityList(provider, colorScheme, isDark),
                  const SizedBox(height: 32),
                  _buildSchedulingControls(context, provider, colorScheme, isDark),
                  const SizedBox(height: 40),
                  _buildSectionLabel('UPCOMING FIELD WORK'),
                  const SizedBox(height: 16),
                  _buildUpcomingList(provider, colorScheme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          provider.tr('Farm Planner'), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5)
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.event_note_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartHero(AppProvider provider, ColorScheme colorScheme) {
    final day = _selectedDay ?? DateTime.now();
    final suggestion = provider.getSuggestedActivity(day);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI RECOMMENDATION', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(suggestion, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: Colors.white54, size: 40),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
          _updateSelectedActivityToSuggestion(selectedDay);
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: colorScheme.primary)),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }

  Widget _buildActivityList(AppProvider provider, ColorScheme colorScheme, bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final act = _activities[index];
          final isSelected = _selectedActivity == act['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedActivity = act['name']),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(act['icon'], color: isSelected ? Colors.white : act['color'], size: 28),
                  const SizedBox(height: 8),
                  Text(provider.tr(act['name']), style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchedulingControls(BuildContext context, AppProvider provider, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
          leading: const Icon(Icons.alarm_rounded),
          title: Text(provider.tr('Reminder Time'), style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(_selectedTime.format(context), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: _selectedTime);
            if (picked != null) setState(() => _selectedTime = picked);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _scheduleActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(provider.tr('Add to Field Schedule').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(AppProvider provider, ColorScheme colorScheme, bool isDark) {
    final upcoming = provider.schedules.where((s) => s.dateTime.isAfter(DateTime.now())).toList();
    if (upcoming.isEmpty) return const Center(child: Text('No tasks scheduled', style: TextStyle(color: Colors.grey)));

    return Column(
      children: upcoming.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ListTile(
          leading: Icon(_getActivityIcon(item.activity), color: colorScheme.primary),
          title: Text(provider.tr(item.activity), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.dateTime)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => provider.deleteSchedule(item.id)),
        ),
      )).toList(),
    );
  }

  void _scheduleActivity() {
    final scheduledDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, _selectedTime.hour, _selectedTime.minute);
    if (scheduledDateTime.isBefore(DateTime.now())) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final newSchedule = Schedule(id: DateTime.now().millisecondsSinceEpoch.toString(), activity: _selectedActivity, dateTime: scheduledDateTime);
    provider.addSchedule(newSchedule);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${provider.tr(_selectedActivity)} Scheduled!'), backgroundColor: Colors.green));
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Scanning': return Icons.qr_code_scanner_rounded;
      case 'Watering': return Icons.water_drop_rounded;
      case 'Pruning': return Icons.content_cut_rounded;
      case 'Fertilizing': return Icons.grain_rounded;
      case 'Pest Control': return Icons.bug_report_rounded;
      default: return Icons.event_note_rounded;
    }
  }
}
