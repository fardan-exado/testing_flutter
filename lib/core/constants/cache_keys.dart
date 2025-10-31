class CacheKeys {
  // Private constructor agar class ini tidak bisa di-instantiate (dibuat objeknya).
  CacheKeys._();

  // Komunitas
  static const String komunitasKategori = 'komunitas_kategori';
  static const String komunitasPostingan = 'komunitas_postingan';
  static String postinganDetail(String artikelId) =>
      'detail_postingan_$artikelId';
  static String komentarPostingan(String artikelId) =>
      'komentar_postingan_$artikelId';

  // Sedekah
  static const String sedekah = 'sedekah';

  // Artikel
  static const String artikelKategori = 'artikel_kategori';
  static const String artikelList = 'artikel';
  static String artikelDetail(int artikelId) => 'detail_artikel_$artikelId';

  // Sholat
  static const String jadwalSholat = 'jadwal_sholat';
  static const String progressSholatWajibHariIni =
      'progress_sholat_wajib_hari_ini';
  static const String progressSholatSunnahHariIni =
      'progress_sholat_sunnah_hari_ini';
  static const String progressSholatWajibRiwayat =
      'progress_sholat_wajib_riwayat';
  static const String progressSholatSunnahRiwayat =
      'progress_sholat_sunnah_riwayat';

  // Home
  static const String homeJadwalSholat = 'home_jadwal_sholat';
  static const String homeLatestArticle = 'home_artikel_terbaru';
  static String homeArtikelDetail(int artikelId) =>
      'home_detail_artikel_$artikelId';
  static const String userLocation = 'user_location';

  // Haji
  static const String hajiList = 'haji_list';
  static String hajiDetail(int hajiId) => 'detail_haji_$hajiId';
}
