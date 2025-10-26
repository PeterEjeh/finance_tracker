// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 5;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      name: fields[1] as String,
      categoryId: fields[2] as String,
      amount: fields[3] as double,
      period: fields[4] as BudgetPeriod,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime,
      userId: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      isActive: fields[10] as bool,
      alertThreshold: fields[11] as double,
      alertEnabled: fields[12] as bool,
      type: fields[13] as BudgetType,
      description: fields[14] as String?,
      currencyCode: fields[15] as String,
      subcategoryId: fields[16] as String?,
      autoRenew: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.alertThreshold)
      ..writeByte(12)
      ..write(obj.alertEnabled)
      ..writeByte(13)
      ..write(obj.type)
      ..writeByte(14)
      ..write(obj.description)
      ..writeByte(15)
      ..write(obj.currencyCode)
      ..writeByte(16)
      ..write(obj.subcategoryId)
      ..writeByte(17)
      ..write(obj.autoRenew);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 6;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.weekly;
      case 1:
        return BudgetPeriod.monthly;
      case 2:
        return BudgetPeriod.quarterly;
      case 3:
        return BudgetPeriod.yearly;
      case 4:
        return BudgetPeriod.custom;
      default:
        return BudgetPeriod.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.weekly:
        writer.writeByte(0);
        break;
      case BudgetPeriod.monthly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.quarterly:
        writer.writeByte(2);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(3);
        break;
      case BudgetPeriod.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetTypeAdapter extends TypeAdapter<BudgetType> {
  @override
  final int typeId = 7;

  @override
  BudgetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetType.progressive;
      case 1:
        return BudgetType.fixed;
      case 2:
        return BudgetType.recurring;
      case 3:
        return BudgetType.goal;
      default:
        return BudgetType.progressive;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetType obj) {
    switch (obj) {
      case BudgetType.progressive:
        writer.writeByte(0);
        break;
      case BudgetType.fixed:
        writer.writeByte(1);
        break;
      case BudgetType.recurring:
        writer.writeByte(2);
        break;
      case BudgetType.goal:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
