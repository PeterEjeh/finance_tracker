// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubcategoryAdapter extends TypeAdapter<Subcategory> {
  @override
  final int typeId = 8;

  @override
  Subcategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subcategory(
      id: fields[0] as String,
      name: fields[1] as String,
      parentCategoryId: fields[2] as String,
      icon: fields[3] as String,
      colorValue: fields[4] as int,
      userId: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      isDefault: fields[8] as bool,
      sortOrder: fields[9] as int,
      description: fields[10] as String?,
      isActive: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Subcategory obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentCategoryId)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isDefault)
      ..writeByte(9)
      ..write(obj.sortOrder)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubcategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
