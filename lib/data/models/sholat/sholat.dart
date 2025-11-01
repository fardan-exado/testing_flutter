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

// class SholatSunnah {
//   final String tahajud;
//   final String witir;
//   final String dhuha;
//   final String qabliyahSubuh;
//   final String qabliyahDzuhur;
//   final String baDiyahDzuhur;
//   final String qabliyahAshar;
//   final String baDiyahMaghrib;
//   final String qabliyahIsya;
//   final String baDiyahIsya;

//   SholatSunnah({
//     required this.tahajud,
//     required this.witir,
//     required this.dhuha,
//     required this.qabliyahSubuh,
//     required this.qabliyahDzuhur,
//     required this.baDiyahDzuhur,
//     required this.qabliyahAshar,
//     required this.baDiyahMaghrib,
//     required this.qabliyahIsya,
//     required this.baDiyahIsya,
//   });

//   factory SholatSunnah.fromJson(Map<String, dynamic> json) {
//     return SholatSunnah(
//       tahajud: json['tahajud'] ?? '',
//       witir: json['witir'] ?? '',
//       dhuha: json['dhuha'] ?? '',
//       qabliyahSubuh: json['qabliyah_subuh'] ?? '',
//       qabliyahDzuhur: json['qabliyah_dzuhur'] ?? '',
//       baDiyahDzuhur: json['ba_diyah_dzuhur'] ?? '',
//       qabliyahAshar: json['qabliyah_ashar'] ?? '',
//       baDiyahMaghrib: json['ba_diyah_maghrib'] ?? '',
//       qabliyahIsya: json['qabliyah_isya'] ?? '',
//       baDiyahIsya: json['ba_diyah_isya'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'tahajud': tahajud,
//       'witir': witir,
//       'dhuha': dhuha,
//       'qabliyah_subuh': qabliyahSubuh,
//       'qabliyah_dzuhur': qabliyahDzuhur,
//       'ba_diyah_dzuhur': baDiyahDzuhur,
//       'qabliyah_ashar': qabliyahAshar,
//       'ba_diyah_maghrib': baDiyahMaghrib,
//       'qabliyah_isya': qabliyahIsya,
//       'ba_diyah_isya': baDiyahIsya,
//     };
//   }
// }
