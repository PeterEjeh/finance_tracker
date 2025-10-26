// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OnboardingDataAdapter extends TypeAdapter<OnboardingData> {
  @override
  final int typeId = 21;

  @override
  OnboardingData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OnboardingData(
      userType: fields[0] as UserType?,
      incomeAmount: fields[1] as double?,
      incomeFrequency: fields[2] as IncomeFrequency?,
      spendingStyle: fields[3] as SpendingStyle?,
      financialGoals: (fields[4] as List?)?.cast<FinancialGoal>(),
      currencyCode: fields[5] as String?,
      preferences: (fields[6] as Map?)?.cast<String, dynamic>(),
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OnboardingData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userType)
      ..writeByte(1)
      ..write(obj.incomeAmount)
      ..writeByte(2)
      ..write(obj.incomeFrequency)
      ..writeByte(3)
      ..write(obj.spendingStyle)
      ..writeByte(4)
      ..write(obj.financialGoals)
      ..writeByte(5)
      ..write(obj.currencyCode)
      ..writeByte(6)
      ..write(obj.preferences)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserTypeAdapter extends TypeAdapter<UserType> {
  @override
  final int typeId = 22;

  @override
  UserType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserType.individual;
      case 1:
        return UserType.business;
      case 2:
        return UserType.student;
      case 3:
        return UserType.freelancer;
      default:
        return UserType.individual;
    }
  }

  @override
  void write(BinaryWriter writer, UserType obj) {
    switch (obj) {
      case UserType.individual:
        writer.writeByte(0);
        break;
      case UserType.business:
        writer.writeByte(1);
        break;
      case UserType.student:
        writer.writeByte(2);
        break;
      case UserType.freelancer:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IncomeFrequencyAdapter extends TypeAdapter<IncomeFrequency> {
  @override
  final int typeId = 23;

  @override
  IncomeFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IncomeFrequency.weekly;
      case 1:
        return IncomeFrequency.biweekly;
      case 2:
        return IncomeFrequency.monthly;
      case 3:
        return IncomeFrequency.quarterly;
      case 4:
        return IncomeFrequency.annually;
      default:
        return IncomeFrequency.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, IncomeFrequency obj) {
    switch (obj) {
      case IncomeFrequency.weekly:
        writer.writeByte(0);
        break;
      case IncomeFrequency.biweekly:
        writer.writeByte(1);
        break;
      case IncomeFrequency.monthly:
        writer.writeByte(2);
        break;
      case IncomeFrequency.quarterly:
        writer.writeByte(3);
        break;
      case IncomeFrequency.annually:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SpendingStyleAdapter extends TypeAdapter<SpendingStyle> {
  @override
  final int typeId = 24;

  @override
  SpendingStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SpendingStyle.conservative;
      case 1:
        return SpendingStyle.moderate;
      case 2:
        return SpendingStyle.aggressive;
      default:
        return SpendingStyle.conservative;
    }
  }

  @override
  void write(BinaryWriter writer, SpendingStyle obj) {
    switch (obj) {
      case SpendingStyle.conservative:
        writer.writeByte(0);
        break;
      case SpendingStyle.moderate:
        writer.writeByte(1);
        break;
      case SpendingStyle.aggressive:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinancialGoalAdapter extends TypeAdapter<FinancialGoal> {
  @override
  final int typeId = 25;

  @override
  FinancialGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FinancialGoal.save_for_emergency;
      case 1:
        return FinancialGoal.buy_house;
      case 2:
        return FinancialGoal.buy_car;
      case 3:
        return FinancialGoal.pay_debt;
      case 4:
        return FinancialGoal.invest;
      case 5:
        return FinancialGoal.travel;
      case 6:
        return FinancialGoal.education;
      case 7:
        return FinancialGoal.retirement;
      default:
        return FinancialGoal.save_for_emergency;
    }
  }

  @override
  void write(BinaryWriter writer, FinancialGoal obj) {
    switch (obj) {
      case FinancialGoal.save_for_emergency:
        writer.writeByte(0);
        break;
      case FinancialGoal.buy_house:
        writer.writeByte(1);
        break;
      case FinancialGoal.buy_car:
        writer.writeByte(2);
        break;
      case FinancialGoal.pay_debt:
        writer.writeByte(3);
        break;
      case FinancialGoal.invest:
        writer.writeByte(4);
        break;
      case FinancialGoal.travel:
        writer.writeByte(5);
        break;
      case FinancialGoal.education:
        writer.writeByte(6);
        break;
      case FinancialGoal.retirement:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
