// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progres_sholat_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgresWajibHariIniCacheAdapter
    extends TypeAdapter<ProgresWajibHariIniCache> {
  @override
  final int typeId = 13;

  @override
  ProgresWajibHariIniCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgresWajibHariIniCache(
      dataJson: fields[0] as String,
      cachedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProgresWajibHariIniCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dataJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgresWajibHariIniCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      dataJson: fields[0] as String,
      cachedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RiwayatProgresWajibCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dataJson)
      ..writeByte(1)
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

class ProgresSunnahHariIniCacheAdapter
    extends TypeAdapter<ProgresSunnahHariIniCache> {
  @override
  final int typeId = 14;

  @override
  ProgresSunnahHariIniCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgresSunnahHariIniCache(
      dataJson: fields[0] as String,
      cachedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProgresSunnahHariIniCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dataJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgresSunnahHariIniCacheAdapter &&
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
      dataJson: fields[0] as String,
      cachedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RiwayatProgresSunnahCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dataJson)
      ..writeByte(1)
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
