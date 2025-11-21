// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kategori_komunitas_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KategoriKomunitasCacheAdapter
    extends TypeAdapter<KategoriKomunitasCache> {
  @override
  final int typeId = 4;

  @override
  KategoriKomunitasCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KategoriKomunitasCache(
      id: fields[0] as int,
      nama: fields[1] as String,
      iconPath: fields[2] as String?,
      icon: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      cachedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, KategoriKomunitasCache obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.iconPath)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KategoriKomunitasCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
