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
    {
      'name': 'Scanning',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Colors.blue,
      'desc': 'Use AI to check for diseases early.',
      'steps': ['Walk diagonally across field', 'Select 10 random leaves', 'Scan with Cabbage Doctor', 'Note high-risk areas']
    },
    {
      'name': 'Watering',
      'icon': Icons.water_drop_rounded,
      'color': Colors.cyan,
      'desc': 'Maintain consistent soil moisture.',
      'steps': ['Check soil 2-inches deep', 'Water at the base of plants', 'Avoid wetting leaves', 'Best done before 9 AM']
    },
    {
      'name': 'Pruning',
      'icon': Icons.content_cut_rounded,
      'color': Colors.orange,
      'desc': 'Remove damaged or infected parts.',
      'steps': ['Identify V-shaped lesions', 'Use sterilized tools', 'Remove lower yellow leaves', 'Dispose debris away from field']
    },
    {
      'name': 'Fertilizing',
      'icon': Icons.grain_rounded,
      'color': Colors.purple,
      'desc': 'Apply nitrogen-rich nutrients.',
      'steps': ['Apply 3 weeks after planting', 'Side-dress 6 inches from stem', 'Water immediately after', 'Follow local dosage guide']
    },
    {
      'name': 'Pest Control',
      'icon': Icons.bug_report_rounded,
      'color': Colors.red,
      'desc': 'Monitor for caterpillars & aphids.',
      'steps': ['Look under leaf surfaces', 'Check for silk or holes', 'Identify beneficial insects', 'Use organic neem spray if needed']
    },
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _scheduleActivity() {
    if (_selectedDay == null) return;

    final scheduledDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future time.')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    
    final newSchedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activity: _selectedActivity,
      dateTime: scheduledDateTime,
    );
    
    provider.addSchedule(newSchedule);

    NotificationService().scheduleNotification(
      newSchedule.id.hashCode,
      'Cabbage Doctor: ${provider.tr(_selectedActivity)}',
      'It\'s time for your scheduled ${provider.tr(_selectedActivity)} task!',
      scheduledDateTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${provider.tr(_selectedActivity)} scheduled for ${DateFormat('MMM dd, hh:mm a').format(scheduledDateTime)}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(AppProvider provider, Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.tr('Delete Schedule?')),
        content: Text(provider.tr('This action cannot be undone.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(provider.tr('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(provider.tr('DELETE')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteSchedule(schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.tr('Schedule deleted permanently'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.tr('Farm Planner')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AI Suggestion Hero
            _buildSmartSuggestionHero(context, provider),

            // 2. Calendar Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(provider.tr('Crop Calendar'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _updateSelectedActivityToSuggestion(selectedDay);
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1),
                  ),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
            ),

            // 3. Activity Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(provider.tr('Choose Activity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final act = _activities[index];
                  final isSelected = _selectedActivity == act['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedActivity = act['name']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
                          boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(act['icon'], color: isSelected ? Colors.white : act['color'], size: 28),
                            const SizedBox(height: 8),
                            Text(
                              provider.tr(act['name']),
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Activity Details & Schedule Button
            _buildActivityDetailsCard(context, provider, colorScheme),

            // 5. Activity Log
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Text(provider.tr('Planned Schedule'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildScheduleList(provider, theme, colorScheme),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSuggestionHero(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final day = _selectedDay ?? DateTime.now();
    final suggestion = provider.getSuggestedActivity(day);
    final isTwi = provider.language == 'Twi';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text(provider.tr('EXPERT CHOICE'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isTwi ? 'Afutuo: $suggestion' : 'Recommended: $suggestion',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.tr('For')} ${DateFormat('EEEE, MMM dd').format(day)}. ${provider.tr('Click to plan it below.')}',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetailsCard(BuildContext context, AppProvider provider, ColorScheme colorScheme) {
    final currentAct = _activities.firstWhere((a) => a['name'] == _selectedActivity);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(currentAct['icon'], color: currentAct['color']),
              const SizedBox(width: 12),
              Text(provider.tr(currentAct['name']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(provider.tr(currentAct['desc']), style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Divider(height: 32),
          Text('${provider.tr('HOW TO DO IT')}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: Colors.grey)),
          const SizedBox(height: 12),
          ...List.generate(currentAct['steps'].length, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                Expanded(child: Text(provider.tr(currentAct['steps'][index]), style: const TextStyle(fontSize: 14))),
              ],
            ),
          )),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.alarm_rounded, size: 18),
              const SizedBox(width: 8),
              Text('${provider.tr('Time')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _scheduleActivity,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(provider.tr('Add to Field Schedule'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    final upcoming = provider.schedules.where((s) => s.dateTime.isAfter(DateTime.now())).toList();
    
    if (upcoming.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(provider.tr('No upcoming tasks.'), style: const TextStyle(color: Colors.grey))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: upcoming.length,
      itemBuilder: (context, index) {
        final item = upcoming[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(_getActivityIcon(item.activity), color: colorScheme.primary),
            title: Text(provider.tr(item.activity), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.dateTime)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _confirmDelete(provider, item),
            ),
          ),
        );
      },
    );
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
