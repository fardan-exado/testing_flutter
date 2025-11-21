class JadwalSholat {
  final String tanggal;
  final Wajib wajib;
  final List<Sunnah> sunnah;

  JadwalSholat({
    required this.tanggal,
    required this.wajib,
    required this.sunnah,
  });

  factory JadwalSholat.fromJson(Map<String, dynamic> json) {
    return JadwalSholat(
      tanggal: json['tanggal'] ?? '',
      wajib: Wajib.fromJson(json['wajib'] ?? {}),
      sunnah: (json['sunnah'] as List? ?? [])
          .map((item) => Sunnah.fromJson(item))
          .toList(),
    );
  }

  /// SAFE EMPTY untuk cache fallback
  factory JadwalSholat.empty() {
    return JadwalSholat(tanggal: '', wajib: Wajib.empty(), sunnah: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal,
      'wajib': wajib.toJson(),
      'sunnah': sunnah.map((item) => item.toJson()).toList(),
    };
  }
}

class Wajib {
  final String imsak;
  final String sunrise;
  final String shubuh;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  Wajib({
    required this.imsak,
    required this.sunrise,
    required this.shubuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory Wajib.fromJson(Map<String, dynamic> json) {
    return Wajib(
      imsak: json['imsak'] ?? '',
      sunrise: json['sunrise'] ?? '',
      shubuh: json['shubuh'] ?? '',
      dzuhur: json['dzuhur'] ?? '',
      ashar: json['ashar'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isya: json['isya'] ?? '',
    );
  }

  factory Wajib.empty() {
    return Wajib(
      imsak: '',
      sunrise: '',
      shubuh: '',
      dzuhur: '',
      ashar: '',
      maghrib: '',
      isya: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imsak': imsak,
      'sunrise': sunrise,
      'shubuh': shubuh,
      'dzuhur': dzuhur,
      'ashar': ashar,
      'maghrib': maghrib,
      'isya': isya,
    };
  }
}

class Sunnah {
  final int id;
  final String? iconPath;
  final String? iconUrl;
  final String nama;
  final String slug;
  final String deskripsi;
  final DateTime createdAt;

  Sunnah({
    required this.id,
    this.iconPath,
    this.iconUrl,
    required this.nama,
    required this.slug,
    required this.deskripsi,
    required this.createdAt,
  });

  factory Sunnah.fromJson(Map<String, dynamic> json) {
    return Sunnah(
      id: json['id'] ?? 0,
      iconPath: json['iconPath'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      nama: json['nama'] ?? '',
      slug: json['slug'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconPath': iconPath,
      'iconUrl': iconUrl,
      'nama': nama,
      'slug': slug,
      'deskripsi': deskripsi,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
