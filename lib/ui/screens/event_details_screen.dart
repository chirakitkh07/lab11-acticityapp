import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/event_provider.dart';
import '../state/category_provider.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/models/reminder.dart';

class EventDetailsScreen extends StatefulWidget {
  final int eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ReminderRepository _reminderRepo = ReminderRepository();
  List<Reminder> _reminders = [];
  bool _isLoadingReminders = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final rems = await _reminderRepo.getRemindersForEvent(widget.eventId);
    setState(() {
      _reminders = rems;
      _isLoadingReminders = false;
    });
  }

  Future<void> _addReminder(int minutesBefore) async {
    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.events.firstWhere(
      (e) => e.id == widget.eventId,
    );

    // actual notification time calculation
    final eventDt = DateTime.parse('${event.eventDate} ${event.startTime}:00');
    final remindAt = eventDt.subtract(Duration(minutes: minutesBefore));

    final reminder = Reminder(
      eventId: widget.eventId,
      minutesBefore: minutesBefore,
      remindAt: remindAt,
      isEnabled: true,
    );

    await _reminderRepo.addReminder(reminder);
    await _loadReminders();
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await _reminderRepo.updateReminder(updated);
    await _loadReminders();
  }

  Future<void> _deleteReminder(int id) async {
    await _reminderRepo.deleteReminder(id);
    await _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    final eventIndex = eventProvider.events.indexWhere(
      (e) => e.id == widget.eventId,
    );
    if (eventIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found or deleted.')),
      );
    }
    final event = eventProvider.events[eventIndex];
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == event.categoryId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await eventProvider.deleteEvent(event.id!);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              backgroundColor: Color(int.parse(category.colorHex)),
              label: Text(
                category.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${event.eventDate}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Time: ${event.startTime} - ${event.endTime}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(event.description!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            DropdownButton<String>(
              value: event.status,
              items: ['pending', 'in_progress', 'completed', 'cancelled']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  eventProvider.updateEventStatus(event.id!, val);
                  if (val == 'completed' || val == 'cancelled') {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      _loadReminders,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Status changed. Active reminders are disabled.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Reminders:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Divider(),
            if (_isLoadingReminders)
              const CircularProgressIndicator()
            else if (_reminders.isEmpty)
              const Text('No reminders set.')
            else
              ..._reminders.map(
                (r) => ListTile(
                  title: Text('${r.minutesBefore} minutes before'),
                  subtitle: Text('At: ${r.remindAt.toString().split('.')[0]}'),
                  trailing: Switch(
                    value: r.isEnabled,
                    onChanged:
                        (event.status == 'completed' ||
                            event.status == 'cancelled')
                        ? null
                        : (_) => _toggleReminder(r),
                  ),
                  onLongPress: () => _deleteReminder(r.id!),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_alert),
              label: const Text('Add Reminder'),
              onPressed: () => _showAddReminderDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    int minutes = 15;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: DropdownButton<int>(
                value: minutes,
                items: [5, 10, 15, 30, 60]
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text('$m minutes before'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateSB(() => minutes = val);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addReminder(minutes);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
