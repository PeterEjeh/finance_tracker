import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _reminderBoxName = 'reminders';
  late Box<Reminder> _reminderBox;

  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = Uuid();

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ReminderTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    _reminderBox = await Hive.openBox<Reminder>(_reminderBoxName);
  }

  List<Reminder> getReminders() {
    return _reminderBox.values.toList();
  }

  Reminder? getReminder(String id) {
    return _reminderBox.get(id);
  }

  Future<void> addReminder(Reminder reminder) async {
    if (reminder.id.isEmpty) {
      reminder.id = _uuid.v4();
    }
    await _reminderBox.put(reminder.id, reminder);
    if (reminder.isEnabled) {
      await _scheduleNotification(reminder);
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _reminderBox.put(reminder.id, reminder);
    await _notificationService.cancelNotification(
      reminder.id.hashCode,
    ); // Cancel existing
    if (reminder.isEnabled) {
      await _scheduleNotification(reminder);
    }
  }

  Future<void> deleteReminder(String id) async {
    await _reminderBox.delete(id);
    await _notificationService.cancelNotification(id.hashCode);
  }

  Future<void> toggleReminderStatus(String id, bool isEnabled) async {
    final reminder = _reminderBox.get(id);
    if (reminder != null) {
      reminder.isEnabled = isEnabled;
      await reminder.save();
      if (isEnabled) {
        await _scheduleNotification(reminder);
      } else {
        await _notificationService.cancelNotification(reminder.id.hashCode);
      }
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    // Implement scheduling logic based on reminder.scheduledTime and type
    // This will involve calling methods on _notificationService
    // For now, a basic implementation:
    await _notificationService.showLocalNotification(
      reminder.id.hashCode,
      reminder.title,
      reminder.message,
      reminder.scheduledTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
}
