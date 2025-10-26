// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CurrencyAdapter extends TypeAdapter<Currency> {
  @override
  final int typeId = 13;

  @override
  Currency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Currency(
      code: fields[0] as String,
      name: fields[1] as String,
      symbol: fields[2] as String,
      flag: fields[3] as String,
      decimalPlaces: fields[4] as int,
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Currency obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.symbol)
      ..writeByte(3)
      ..write(obj.flag)
      ..writeByte(4)
      ..write(obj.decimalPlaces)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExchangeRateAdapter extends TypeAdapter<ExchangeRate> {
  @override
  final int typeId = 14;

  @override
  ExchangeRate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRate(
      id: fields[0] as String,
      fromCurrency: fields[1] as String,
      toCurrency: fields[2] as String,
      rate: fields[3] as double,
      date: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      source: fields[7] as ExchangeRateSource,
      isHistorical: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRate obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromCurrency)
      ..writeByte(2)
      ..write(obj.toCurrency)
      ..writeByte(3)
      ..write(obj.rate)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.isHistorical);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CurrencyAmountAdapter extends TypeAdapter<CurrencyAmount> {
  @override
  final int typeId = 15;

  @override
  CurrencyAmount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CurrencyAmount(
      amount: fields[0] as double,
      currencyCode: fields[1] as String,
      convertedAmount: fields[2] as double?,
      baseCurrencyCode: fields[3] as String?,
      exchangeRate: fields[4] as double?,
      exchangeRateDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CurrencyAmount obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.currencyCode)
      ..writeByte(2)
      ..write(obj.convertedAmount)
      ..writeByte(3)
      ..write(obj.baseCurrencyCode)
      ..writeByte(4)
      ..write(obj.exchangeRate)
      ..writeByte(5)
      ..write(obj.exchangeRateDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyAmountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExchangeRateSourceAdapter extends TypeAdapter<ExchangeRateSource> {
  @override
  final int typeId = 16;

  @override
  ExchangeRateSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExchangeRateSource.api;
      case 1:
        return ExchangeRateSource.manual;
      case 2:
        return ExchangeRateSource.cached;
      case 3:
        return ExchangeRateSource.historical;
      default:
        return ExchangeRateSource.api;
    }
  }

  @override
  void write(BinaryWriter writer, ExchangeRateSource obj) {
    switch (obj) {
      case ExchangeRateSource.api:
        writer.writeByte(0);
        break;
      case ExchangeRateSource.manual:
        writer.writeByte(1);
        break;
      case ExchangeRateSource.cached:
        writer.writeByte(2);
        break;
      case ExchangeRateSource.historical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
