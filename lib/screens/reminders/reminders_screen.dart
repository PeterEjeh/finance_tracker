import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Import Uuid
import '../../models/reminder.dart';
import '../../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late ReminderService _reminderService;
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _reminderService = Provider.of<ReminderService>(context, listen: false);
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    _reminders = _reminderService.getReminders();
    setState(() {});
  }

  Future<void> _addOrEditReminder({Reminder? reminder}) async {
    final TextEditingController titleController = TextEditingController(
      text: reminder?.title ?? '',
    );
    final TextEditingController messageController = TextEditingController(
      text: reminder?.message ?? '',
    );
    ReminderType? selectedType = reminder?.type;
    DateTime? selectedScheduledTime = reminder?.scheduledTime;
    bool isEnabled = reminder?.isEnabled ?? true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder == null ? 'Add Reminder' : 'Edit Reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              DropdownButtonFormField<ReminderType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Reminder Type'),
                items: ReminderType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedType = value;
                },
              ),
              ListTile(
                title: Text(
                  selectedScheduledTime == null
                      ? 'Select Date & Time'
                      : 'Scheduled: ${selectedScheduledTime?.toLocal()}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedScheduledTime ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        selectedScheduledTime ?? DateTime.now(),
                      ),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedScheduledTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Enable Reminder'),
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    isEnabled = value;
                  });
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
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  messageController.text.isEmpty ||
                  selectedType == null ||
                  selectedScheduledTime == null) {
                // Show error
                return;
              }

              final newReminder = Reminder(
                id: reminder?.id ?? const Uuid().v4(),
                title: titleController.text,
                message: messageController.text,
                type: selectedType!,
                scheduledTime: selectedScheduledTime!,
                isEnabled: isEnabled,
              );

              if (reminder == null) {
                await _reminderService.addReminder(newReminder);
              } else {
                await _reminderService.updateReminder(newReminder);
              }
              _loadReminders();
              Navigator.pop(context);
            },
            child: Text(reminder == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(reminder.title),
              subtitle: Text(
                '${reminder.message}\nType: ${reminder.type.toString().split('.').last}\nScheduled: ${reminder.scheduledTime.toLocal()}',
              ),
              trailing: Switch(
                value: reminder.isEnabled,
                onChanged: (value) async {
                  await _reminderService.toggleReminderStatus(
                    reminder.id,
                    value,
                  );
                  _loadReminders();
                },
              ),
              onTap: () => _addOrEditReminder(reminder: reminder),
              onLongPress: () async {
                await _reminderService.deleteReminder(reminder.id);
                _loadReminders();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditReminder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
