import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../services/notification_service.dart';

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

  // List of possible farming activities with descriptions
  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Scanning',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Colors.blue,
      'desc': 'Use AI to check for diseases.'
    },
    {
      'name': 'Watering',
      'icon': Icons.water_drop_rounded,
      'color': Colors.cyan,
      'desc': 'Ensures soil moisture is optimal.'
    },
    {
      'name': 'Pruning',
      'icon': Icons.content_cut_rounded,
      'color': Colors.orange,
      'desc': 'Remove infected or dead leaves.'
    },
    {
      'name': 'Fertilizing',
      'icon': Icons.grain_rounded,
      'color': Colors.purple,
      'desc': 'Apply nutrients for head growth.'
    },
    {
      'name': 'Pest Control',
      'icon': Icons.bug_report_rounded,
      'color': Colors.red,
      'desc': 'Inspect for aphids or caterpillars.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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

    NotificationService().scheduleNotification(
      _selectedActivity.hashCode,
      'Cabbage Doctor Reminder',
      'It\'s time for your scheduled $_selectedActivity task!',
      scheduledDateTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedActivity reminder set for ${DateFormat('MMM dd, hh:mm a').format(scheduledDateTime)}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Planner'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AI Suggestion Section
            _buildSmartSuggestionSection(context, provider),

            // 2. Calendar Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Select Date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
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
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1),
                  ),
                  todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
            ),

            // 3. Plan Activity Section
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text('Plan Your Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            SizedBox(
              height: 120,
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
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(act['icon'], color: isSelected ? Colors.white : act['color'], size: 32),
                            const SizedBox(height: 8),
                            Text(
                              act['name'],
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

            // 4. Time Picker & Action
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _selectTime(context),
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: Text(
                            _selectedTime.format(context),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _scheduleActivity,
                        icon: const Icon(Icons.notification_add_rounded),
                        label: Text('Set Reminder for $_selectedActivity'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Activity Log
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text('Recent Logged Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildActivityLog(provider, theme, colorScheme),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSuggestionSection(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final day = _selectedDay ?? DateTime.now();
    final suggestion = provider.getSuggestedActivity(day);
    
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
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'SMART SUGGESTION FOR ${DateFormat('EEEE').format(day).toUpperCase()}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We recommend doing a "$suggestion" session.',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _getSuggestionDetails(suggestion),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _getSuggestionDetails(String suggestion) {
    if (suggestion.contains('Water')) return 'Proper hydration is critical for head formation. Best done before 9 AM.';
    if (suggestion.contains('Scan')) return 'Check at least 10 leaves from different parts of your field for accuracy.';
    if (suggestion.contains('Pruning')) return 'Cleaning the field reduces the risk of Black Rot spreading through soil splash.';
    if (suggestion.contains('Fertilizer')) return 'Nitrogen-rich fertilizer helps cabbage grow large and healthy heads.';
    return 'Regular scouting helps you find issues before they become a problem.';
  }

  Widget _buildActivityLog(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    if (provider.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('No history available yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.history.length > 5 ? 5 : provider.history.length,
      itemBuilder: (context, index) {
        final item = provider.history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item.diseaseName == 'Healthy' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                item.diseaseName == 'Healthy' ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: item.diseaseName == 'Healthy' ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(item.diseaseName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM dd - hh:mm a').format(item.dateTime)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ),
        );
      },
    );
  }
}
