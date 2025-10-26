// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_contribution.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsContributionAdapter extends TypeAdapter<SavingsContribution> {
  @override
  final int typeId = 11;

  @override
  SavingsContribution read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsContribution(
      id: fields[0] as String,
      savingsGoalId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
      userId: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      currencyCode: fields[8] as String,
      type: fields[9] as SavingsContributionType,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsContribution obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.savingsGoalId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.currencyCode)
      ..writeByte(9)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsContributionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsContributionTypeAdapter
    extends TypeAdapter<SavingsContributionType> {
  @override
  final int typeId = 12;

  @override
  SavingsContributionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavingsContributionType.manual;
      case 1:
        return SavingsContributionType.automatic;
      default:
        return SavingsContributionType.manual;
    }
  }

  @override
  void write(BinaryWriter writer, SavingsContributionType obj) {
    switch (obj) {
      case SavingsContributionType.manual:
        writer.writeByte(0);
        break;
      case SavingsContributionType.automatic:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsContributionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
