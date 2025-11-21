// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sholat_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SholatCacheAdapter extends TypeAdapter<SholatCache> {
  @override
  final int typeId = 7;

  @override
  SholatCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SholatCache(
      tanggal: fields[0] as String,
      wajib: fields[1] as SholatWajib,
      sunnah: (fields[2] as List).cast<SholatSunnah>(),
      cachedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SholatCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tanggal)
      ..writeByte(1)
      ..write(obj.wajib)
      ..writeByte(2)
      ..write(obj.sunnah)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SholatCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
