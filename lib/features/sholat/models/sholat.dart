class Sholat {
  final String tanggal;
  final SholatWajib wajib;
  final List<SholatSunnah> sunnah;

  Sholat({required this.tanggal, required this.wajib, required this.sunnah});

  factory Sholat.fromJson(Map<String, dynamic> json) {
    return Sholat(
      tanggal: json['tanggal'],
      wajib: SholatWajib.fromJson(json['wajib']),
      sunnah: (json['sunnah'] as List)
          .map((item) => SholatSunnah.fromJson(item))
          .toList(),
    );
  }

  factory Sholat.empty() {
    return Sholat(
      tanggal: '',
      wajib: SholatWajib(
        imsak: '',
        sunrise: '',
        shubuh: '',
        dzuhur: '',
        ashar: '',
        maghrib: '',
        isya: '',
      ),
      sunnah: [
        SholatSunnah(id: 0, icon: '', nama: '', slug: '', deskripsi: ''),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal,
      'wajib': wajib.toJson(),
      'sunnah': sunnah.map((item) => item.toJson()).toList(),
    };
  }
}

class SholatWajib {
  final String imsak;
  final String sunrise;
  final String shubuh;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  SholatWajib({
    required this.imsak,
    required this.sunrise,
    required this.shubuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory SholatWajib.fromJson(Map<String, dynamic> json) {
    return SholatWajib(
      imsak: json['imsak'] ?? '',
      sunrise: json['sunrise'] ?? '',
      shubuh: json['shubuh'] ?? '',
      dzuhur: json['dzuhur'] ?? '',
      ashar: json['ashar'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isya: json['isya'] ?? '',
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

  // Get prayer time by name
  String getTimeByName(String name) {
    switch (name.toLowerCase()) {
      case 'imsak':
        return imsak;
      case 'sunrise':
        return sunrise;
      case 'shubuh':
        return shubuh;
      case 'dzuhur':
      case 'dhuhr':
        return dzuhur;
      case 'ashar':
      case 'asr':
        return ashar;
      case 'maghrib':
        return maghrib;
      case 'isya':
      case 'isha':
        return isya;
      default:
        return '';
    }
  }

  // Get all prayer times as list
  List<Map<String, String>> getAllPrayerTimes() {
    return [
      {'name': 'Imsak', 'time': imsak},
      {'name': 'Sunrise', 'time': sunrise},
      {'name': 'Shubuh', 'time': shubuh},
      {'name': 'Dzuhr', 'time': dzuhur},
      {'name': 'Asr', 'time': ashar},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isya},
    ];
  }
}

class SholatSunnah {
  final int id;
  final String? icon;
  final String nama;
  final String slug;
  final String deskripsi;

  SholatSunnah({
    required this.id,
    this.icon,
    required this.nama,
    required this.slug,
    required this.deskripsi,
  });

  factory SholatSunnah.fromJson(Map<String, dynamic> json) {
    return SholatSunnah(
      id: json['id'] ?? 0,
      icon: json['icon'],
      nama: json['nama'] ?? '',
      slug: json['slug'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon,
      'nama': nama,
      'slug': slug,
      'deskripsi': deskripsi,
    };
  }
}

class ProgressSholatSunnahHariIni {
  final List<SholatSunnah> sholatSunnah;
  final bool progress;

  ProgressSholatSunnahHariIni({
    required this.sholatSunnah,
    required this.progress,
  });

  factory ProgressSholatSunnahHariIni.fromJson(Map<String, dynamic> json) {
    return ProgressSholatSunnahHariIni(
      sholatSunnah: (json['sholat_sunnah'] as List)
          .map((item) => SholatSunnah.fromJson(item))
          .toList(),
      progress: json['progress'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sholat_sunnah': sholatSunnah.map((item) => item.toJson()).toList(),
      'progress': progress,
    };
  }
}
