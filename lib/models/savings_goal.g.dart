// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsGoalAdapter extends TypeAdapter<SavingsGoal> {
  @override
  final int typeId = 9;

  @override
  SavingsGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      targetAmount: fields[3] as double,
      currentAmount: fields[4] as double,
      targetDate: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      userId: fields[8] as String,
      currencyCode: fields[9] as String,
      isActive: fields[10] as bool,
      isCompleted: fields[11] as bool,
      completedAt: fields[12] as DateTime?,
      contributionFrequency: fields[13] as SavingsGoalFrequency,
      suggestedContribution: fields[14] as double?,
      categoryId: fields[15] as String?,
      alertEnabled: fields[16] as bool,
      alertThreshold: fields[17] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoal obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.currentAmount)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.currencyCode)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.contributionFrequency)
      ..writeByte(14)
      ..write(obj.suggestedContribution)
      ..writeByte(15)
      ..write(obj.categoryId)
      ..writeByte(16)
      ..write(obj.alertEnabled)
      ..writeByte(17)
      ..write(obj.alertThreshold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsGoalFrequencyAdapter extends TypeAdapter<SavingsGoalFrequency> {
  @override
  final int typeId = 10;

  @override
  SavingsGoalFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavingsGoalFrequency.daily;
      case 1:
        return SavingsGoalFrequency.weekly;
      case 2:
        return SavingsGoalFrequency.monthly;
      default:
        return SavingsGoalFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, SavingsGoalFrequency obj) {
    switch (obj) {
      case SavingsGoalFrequency.daily:
        writer.writeByte(0);
        break;
      case SavingsGoalFrequency.weekly:
        writer.writeByte(1);
        break;
      case SavingsGoalFrequency.monthly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
