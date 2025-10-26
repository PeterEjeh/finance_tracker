// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpendingReportAdapter extends TypeAdapter<SpendingReport> {
  @override
  final int typeId = 17;

  @override
  SpendingReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpendingReport(
      id: fields[0] as String,
      userId: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      period: fields[4] as ReportPeriod,
      totalIncome: fields[5] as double,
      totalExpenses: fields[6] as double,
      netAmount: fields[7] as double,
      categoryBreakdown: (fields[8] as List).cast<CategorySpending>(),
      dailyBreakdown: (fields[9] as List).cast<DailySpending>(),
      createdAt: fields[10] as DateTime,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SpendingReport obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.totalIncome)
      ..writeByte(6)
      ..write(obj.totalExpenses)
      ..writeByte(7)
      ..write(obj.netAmount)
      ..writeByte(8)
      ..write(obj.categoryBreakdown)
      ..writeByte(9)
      ..write(obj.dailyBreakdown)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategorySpendingAdapter extends TypeAdapter<CategorySpending> {
  @override
  final int typeId = 18;

  @override
  CategorySpending read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategorySpending(
      categoryId: fields[0] as String,
      categoryName: fields[1] as String,
      categoryIcon: fields[2] as String,
      categoryColor: fields[3] as int,
      totalAmount: fields[4] as double,
      transactionCount: fields[5] as int,
      percentage: fields[6] as double,
      transactions: (fields[7] as List).cast<Transaction>(),
    );
  }

  @override
  void write(BinaryWriter writer, CategorySpending obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.categoryIcon)
      ..writeByte(3)
      ..write(obj.categoryColor)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.transactionCount)
      ..writeByte(6)
      ..write(obj.percentage)
      ..writeByte(7)
      ..write(obj.transactions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpendingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailySpendingAdapter extends TypeAdapter<DailySpending> {
  @override
  final int typeId = 19;

  @override
  DailySpending read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySpending(
      date: fields[0] as DateTime,
      totalIncome: fields[1] as double,
      totalExpenses: fields[2] as double,
      netAmount: fields[3] as double,
      transactionCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailySpending obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalIncome)
      ..writeByte(2)
      ..write(obj.totalExpenses)
      ..writeByte(3)
      ..write(obj.netAmount)
      ..writeByte(4)
      ..write(obj.transactionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySpendingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReportPeriodAdapter extends TypeAdapter<ReportPeriod> {
  @override
  final int typeId = 20;

  @override
  ReportPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReportPeriod.daily;
      case 1:
        return ReportPeriod.weekly;
      case 2:
        return ReportPeriod.monthly;
      case 3:
        return ReportPeriod.quarterly;
      case 4:
        return ReportPeriod.yearly;
      case 5:
        return ReportPeriod.custom;
      default:
        return ReportPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, ReportPeriod obj) {
    switch (obj) {
      case ReportPeriod.daily:
        writer.writeByte(0);
        break;
      case ReportPeriod.weekly:
        writer.writeByte(1);
        break;
      case ReportPeriod.monthly:
        writer.writeByte(2);
        break;
      case ReportPeriod.quarterly:
        writer.writeByte(3);
        break;
      case ReportPeriod.yearly:
        writer.writeByte(4);
        break;
      case ReportPeriod.custom:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
