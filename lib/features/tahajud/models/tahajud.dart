class Tahajud {
  final int id;
  final int userId;
  final DateTime? waktuSholat;
  final int? jumlahRakaat;
  final DateTime? waktuMakanTerakhir;
  final DateTime? waktuTidur;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tahajud({
    required this.id,
    required this.userId,
    this.waktuSholat,
    this.jumlahRakaat,
    this.waktuMakanTerakhir,
    this.waktuTidur,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
  });

  factory Tahajud.fromJson(Map<String, dynamic> json) {
    return Tahajud(
      id: json['id'],
      userId: json['user_id'],
      waktuSholat: json['waktu_sholat'] != null
          ? DateTime.parse(json['waktu_sholat'])
          : null,
      jumlahRakaat: json['jumlah_rakaat'],
      waktuMakanTerakhir: json['waktu_makan_terakhir'] != null
          ? DateTime.parse(json['waktu_makan_terakhir'])
          : null,
      waktuTidur: json['waktu_tidur'] != null
          ? DateTime.parse(json['waktu_tidur'])
          : null,
      keterangan: json['keterangan'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'waktu_sholat': waktuSholat?.toIso8601String(),
      'jumlah_rakaat': jumlahRakaat,
      'waktu_makan_terakhir': waktuMakanTerakhir?.toIso8601String(),
      'waktu_tidur': waktuTidur?.toIso8601String(),
      'keterangan': keterangan,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class RiwayatTahajud {
  final DateTime tanggal;
  final bool status;
  final Tahajud? tahajud;

  RiwayatTahajud({required this.tanggal, required this.status, this.tahajud});

  factory RiwayatTahajud.fromJson(Map<String, dynamic> json) {
    return RiwayatTahajud(
      tanggal: DateTime.parse(json['tanggal']),
      status: json['status'],
      tahajud: json['tahajud'] != null
          ? Tahajud.fromJson(json['tahajud'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal.toIso8601String(),
      'status': status,
      'tahajud': tahajud?.toJson(),
    };
  }
}

class StatistikTahajud {
  final int streakBulanIni;
  final int totalTahajudKeseluruhan;
  final int totalTahajudBulanIni;
  final int jumlahHariBulanIni;

  StatistikTahajud({
    required this.streakBulanIni,
    required this.totalTahajudKeseluruhan,
    required this.totalTahajudBulanIni,
    required this.jumlahHariBulanIni,
  });

  factory StatistikTahajud.fromJson(Map<String, dynamic> json) {
    return StatistikTahajud(
      streakBulanIni: json['streak_bulan_ini'] ?? 0,
      totalTahajudKeseluruhan: json['total_tahajud_keseluruhan'] ?? 0,
      totalTahajudBulanIni: json['total_tahajud_bulan_ini'] ?? 0,
      jumlahHariBulanIni: json['jumlah_hari_bulan_ini'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak_bulan_ini': streakBulanIni,
      'total_tahajud_keseluruhan': totalTahajudKeseluruhan,
      'total_tahajud_bulan_ini': totalTahajudBulanIni,
      'jumlah_hari_bulan_ini': jumlahHariBulanIni,
    };
  }
}
