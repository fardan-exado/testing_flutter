// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'haji_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HajiCacheAdapter extends TypeAdapter<HajiCache> {
  @override
  final int typeId = 24;

  @override
  HajiCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HajiCache(
      id: fields[0] as int,
      judul: fields[1] as String,
      cover: fields[2] as String,
      tipe: fields[3] as String,
      videoUrl: fields[4] as String?,
      konten: fields[10] as String?,
      daftarGambar: (fields[5] as List?)?.cast<String>(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      excerpt: fields[8] as String?,
      penulis: fields[9] as String?,
      cachedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HajiCache obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.cover)
      ..writeByte(3)
      ..write(obj.tipe)
      ..writeByte(4)
      ..write(obj.videoUrl)
      ..writeByte(5)
      ..write(obj.daftarGambar)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.excerpt)
      ..writeByte(9)
      ..write(obj.penulis)
      ..writeByte(10)
      ..write(obj.konten)
      ..writeByte(11)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HajiCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
