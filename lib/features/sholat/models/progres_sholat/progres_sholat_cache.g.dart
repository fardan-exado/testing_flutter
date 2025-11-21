// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progres_sholat_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RiwayatProgresWajibCacheAdapter
    extends TypeAdapter<RiwayatProgresWajibCache> {
  @override
  final int typeId = 15;

  @override
  RiwayatProgresWajibCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RiwayatProgresWajibCache(
      sholatWajib: fields[0] as SholatWajib,
      status: fields[1] as bool,
      progress: fields[2] as ProgresWajibDetail?,
      cachedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RiwayatProgresWajibCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sholatWajib)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.progress)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiwayatProgresWajibCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RiwayatProgresSunnahCacheAdapter
    extends TypeAdapter<RiwayatProgresSunnahCache> {
  @override
  final int typeId = 16;

  @override
  RiwayatProgresSunnahCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RiwayatProgresSunnahCache(
      sholatSunnah: fields[0] as Sunnah,
      status: fields[1] as bool,
      progress: fields[2] as ProgresSunnahDetail?,
      cachedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RiwayatProgresSunnahCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sholatSunnah)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.progress)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiwayatProgresSunnahCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
