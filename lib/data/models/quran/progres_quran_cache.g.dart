// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progres_quran_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgresBacaQuranCacheAdapter extends TypeAdapter<ProgresBacaQuranCache> {
  @override
  final int typeId = 25;

  @override
  ProgresBacaQuranCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgresBacaQuranCache(
      id: fields[0] as int,
      userId: fields[1] as int,
      suratId: fields[2] as int,
      ayat: fields[3] as int,
      createdAt: fields[4] as String?,
      surat: (fields[5] as Map?)?.cast<String, dynamic>(),
      cachedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProgresBacaQuranCache obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.suratId)
      ..writeByte(3)
      ..write(obj.ayat)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.surat)
      ..writeByte(6)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgresBacaQuranCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
