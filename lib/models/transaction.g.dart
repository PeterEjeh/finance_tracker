// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      categoryId: fields[3] as String,
      type: fields[4] as TransactionType,
      date: fields[5] as DateTime,
      description: fields[6] as String?,
      receiptImagePath: fields[7] as String?,
      userId: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      tags: fields[11] as String?,
      location: fields[12] as String?,
      isRecurring: fields[13] as bool,
      recurringType: fields[14] as RecurringType?,
      nextRecurringDate: fields[15] as DateTime?,
      currencyCode: fields[16] as String,
      originalAmount: fields[17] as double?,
      originalCurrencyCode: fields[18] as String?,
      exchangeRate: fields[19] as double?,
      convertedAmount: fields[20] as double?,
      subcategoryId: fields[21] as String?,
      budgetId: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.receiptImagePath)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.location)
      ..writeByte(13)
      ..write(obj.isRecurring)
      ..writeByte(14)
      ..write(obj.recurringType)
      ..writeByte(15)
      ..write(obj.nextRecurringDate)
      ..writeByte(16)
      ..write(obj.currencyCode)
      ..writeByte(17)
      ..write(obj.originalAmount)
      ..writeByte(18)
      ..write(obj.originalCurrencyCode)
      ..writeByte(19)
      ..write(obj.exchangeRate)
      ..writeByte(20)
      ..write(obj.convertedAmount)
      ..writeByte(21)
      ..write(obj.subcategoryId)
      ..writeByte(22)
      ..write(obj.budgetId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 1;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.saving;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.saving:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringTypeAdapter extends TypeAdapter<RecurringType> {
  @override
  final int typeId = 2;

  @override
  RecurringType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringType.daily;
      case 1:
        return RecurringType.weekly;
      case 2:
        return RecurringType.monthly;
      case 3:
        return RecurringType.yearly;
      default:
        return RecurringType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringType obj) {
    switch (obj) {
      case RecurringType.daily:
        writer.writeByte(0);
        break;
      case RecurringType.weekly:
        writer.writeByte(1);
        break;
      case RecurringType.monthly:
        writer.writeByte(2);
        break;
      case RecurringType.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
