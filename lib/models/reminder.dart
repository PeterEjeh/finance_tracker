import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 10) // Assign a unique typeId
enum ReminderType {
  @HiveField(0)
  bill,
  @HiveField(1)
  goalProgress,
  @HiveField(2)
  budgetExceeded,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 11) // Assign a unique typeId
class Reminder extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String message;
  @HiveField(3)
  ReminderType type;
  @HiveField(4)
  DateTime scheduledTime;
  @HiveField(5)
  bool isEnabled;
  @HiveField(6)
  String? relatedId; // e.g., budgetId, savingsGoalId, transactionId

  Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.scheduledTime,
    this.isEnabled = true,
    this.relatedId,
  });
}
