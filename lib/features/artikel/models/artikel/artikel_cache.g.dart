// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artikel_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtikelCacheAdapter extends TypeAdapter<ArtikelCache> {
  @override
  final int typeId = 3;

  @override
  ArtikelCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtikelCache(
      id: fields[0] as int,
      kategoriId: fields[1] as int,
      judul: fields[2] as String,
      coverPath: fields[3] as String,
      tipe: fields[4] as String,
      videoUrl: fields[5] as String?,
      konten: fields[12] as String?,
      daftarGambar: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      excerpt: fields[9] as String?,
      penulis: fields[10] as String?,
      kategori: fields[11] as KategoriArtikelCache,
      cachedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ArtikelCache obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kategoriId)
      ..writeByte(2)
      ..write(obj.judul)
      ..writeByte(3)
      ..write(obj.coverPath)
      ..writeByte(4)
      ..write(obj.tipe)
      ..writeByte(5)
      ..write(obj.videoUrl)
      ..writeByte(6)
      ..write(obj.daftarGambar)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.excerpt)
      ..writeByte(10)
      ..write(obj.penulis)
      ..writeByte(11)
      ..write(obj.kategori)
      ..writeByte(12)
      ..write(obj.konten)
      ..writeByte(13)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtikelCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
