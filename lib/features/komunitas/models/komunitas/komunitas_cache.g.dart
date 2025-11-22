// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'komunitas_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KomunitasPostinganCacheAdapter
    extends TypeAdapter<KomunitasPostinganCache> {
  @override
  final int typeId = 5;

  @override
  KomunitasPostinganCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KomunitasPostinganCache(
      id: fields[0] as int,
      userId: fields[1] as int?,
      postinganId: fields[2] as int?,
      judul: fields[3] as String,
      konten: fields[4] as String?,
      excerpt: fields[5] as String,
      isAnonymous: fields[6] as bool,
      isPublished: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      cachedAt: fields[10] as DateTime,
      kategori: fields[11] as KategoriArtikelCache?,
      likesCount: fields[12] as int?,
      komentarsCount: fields[13] as int?,
      liked: fields[14] as bool?,
      daftarGambar: (fields[15] as List?)?.cast<String>(),
      coverPath: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KomunitasPostinganCache obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.postinganId)
      ..writeByte(3)
      ..write(obj.judul)
      ..writeByte(4)
      ..write(obj.konten)
      ..writeByte(5)
      ..write(obj.excerpt)
      ..writeByte(6)
      ..write(obj.isAnonymous)
      ..writeByte(7)
      ..write(obj.isPublished)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.cachedAt)
      ..writeByte(11)
      ..write(obj.kategori)
      ..writeByte(12)
      ..write(obj.likesCount)
      ..writeByte(13)
      ..write(obj.komentarsCount)
      ..writeByte(14)
      ..write(obj.liked)
      ..writeByte(15)
      ..write(obj.daftarGambar)
      ..writeByte(16)
      ..write(obj.coverPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KomunitasPostinganCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KomentarPostinganCacheAdapter
    extends TypeAdapter<KomentarPostinganCache> {
  @override
  final int typeId = 6;

  @override
  KomentarPostinganCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KomentarPostinganCache(
      id: fields[0] as int,
      postinganId: fields[1] as int,
      userId: fields[2] as int,
      komentar: fields[3] as String,
      isAnonymous: fields[4] as bool?,
      isPublished: fields[5] as bool?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      cachedAt: fields[9] as DateTime,
      user: fields[8] as User?,
    );
  }

  @override
  void write(BinaryWriter writer, KomentarPostinganCache obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.postinganId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.komentar)
      ..writeByte(4)
      ..write(obj.isAnonymous)
      ..writeByte(5)
      ..write(obj.isPublished)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.user)
      ..writeByte(9)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KomentarPostinganCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
