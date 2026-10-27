/// Data referensi Jurusan, Program Studi, Laboratorium, Unit, dan Kota
/// Politeknik Negeri Jember (POLIJE) — port 1:1 dari `src/data/polije-data.js`
/// dan `src/pages/user/buat-laporan.jsx`.
class PolijeJurusanData {
  final String jurusan;
  final List<String> prodi;
  final List<String> lab;

  const PolijeJurusanData({
    required this.jurusan,
    required this.prodi,
    required this.lab,
  });
}

class PolijeData {
  PolijeData._();

  static const List<PolijeJurusanData> data = [
    PolijeJurusanData(
      jurusan: 'Jurusan Teknik',
      prodi: [
        'D4 Teknik Energi Terbarukan',
        'D4 Mesin Otomotif',
        'D4 Teknologi Rekayasa Mekatronika',
      ],
      lab: [
        'Perawatan Otomotif',
        'Rekayasa Otomotif',
        'Listrik dan Pembangkitan Daya',
        'Workshop Energi dan Mekanik',
        'Elektronika Instrumentasi',
        'Otomasi',
        'Gambar dan Komputasi',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Kesehatan',
      prodi: [
        'D4 Manajemen Informasi Kesehatan',
        'D4 Gizi Klinik',
        'D4 Promosi Kesehatan',
      ],
      lab: [
        'Laboratorium Statistik dan Pelaporan',
        'Laboratorium Koding Klinis & Reimbursment',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Bahasa, Komunikasi, dan Pariwisata',
      prodi: [
        'D4 Bahasa Inggris',
        'D4 Destinasi Pariwisata',
        'D4 Produksi Media',
      ],
      lab: [
        'Laboratorium Perhotelan Terpadu',
        'Laboratorium Bahasa',
        'Laboratorium Multimedia',
        'Laboratorium Perencanaan Kepariwisataan (Proses Pengusulan)',
        'Laboratorium Media dan Publikasi',
        'Laboratorium Podcast dan Broadcast',
        'Laboratorium Videografi',
        'Laboratorium Fotografi dan Visual',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Bisnis',
      prodi: [
        'D4 Akuntansi Sektor Publik',
        'D4 Bisnis Digital',
        'D4 Manajemen Pemasaran Internasional',
      ],
      lab: [
        'Laboratorium Akuntansi',
        'Laboratorium Digital Marketing',
        'Laboratorium Bahasa Bisnis',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Teknologi Pertanian',
      prodi: [
        'Keteknikan Pertanian',
        'Teknologi Industri Pangan',
        'Teknologi Rekayasa Pangan',
        'Teknologi Rekayasa Pengemasan',
      ],
      lab: [
        'Laboratorium dan Lahan Percobaan',
        'Laboratorium Komputer',
        'Ruang Gambar dan Laboratorium Komputer',
        'Lab. Alat dan Mesin',
        'Lab. Analisis Pangan',
        'Lab. Biosain',
        'Lab. Pengolahan Pangan',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Peternakan',
      prodi: [
        'Produksi Ternak',
        'Manajemen Bisnis Unggas',
        'Teknologi Pakan Ternak',
      ],
      lab: [
        'Lab. Biosain',
        'Lab. Produksi Ternak',
        'Lab. Produksi Ternak dan Lab. Lapang',
        'Lab. Komputer',
        'Lab. Nutrisi Ternak',
        'UPT Pakan Ternak Kandang',
        'Kandang Unggas',
        'Lab. Teknologi Pakan',
        'Pabrik Pakan',
        'Kandang Feedloot',
        'Kandang Sapi',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Manajemen Agribisnis',
      prodi: [
        'Manajemen Agribisnis',
        'Manajemen Agroindustri',
        'Pascasarjana Agribisnis',
      ],
      lab: [
        'Lab. Kewirausahaan Agribisnis',
        'Lab. Komputer',
        'Lab. Komunikasi Bisnis',
        'Laboratorium Komputer MID',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Jurusan Teknologi Informasi',
      prodi: [
        'Manajemen Informatika',
        'Teknik Komputer',
        'Teknik Informatika',
        'Teknologi Rekayasa Komputer',
      ],
      lab: [
        'Lab. Komputasi & Sistem Informasi',
        'Lab. Rekayasa Sistem Informasi',
        'Lab. Arsitektur & Jaringan Komputer',
        'Lab. Sistem Komputer & Kontrol',
        'Lab. Rekayasa Perangkat Lunak',
        'Lab. Multimedia',
      ],
    ),
    PolijeJurusanData(
      jurusan: 'Kelas Internasional',
      prodi: [
        'Manajemen Informatika Internasional',
        'Teknik Informatika Internasional',
        'Manajemen Agroindustri Internasional',
      ],
      lab: [],
    ),
  ];

  static List<String> get jurusanList =>
      data.map((e) => e.jurusan).toList(growable: false);

  static List<String> getProdiByJurusan(String? jurusan) {
    if (jurusan == null || jurusan.isEmpty) return const [];
    for (final item in data) {
      if (item.jurusan == jurusan) return item.prodi;
    }
    return const [];
  }

  static List<String> getLabByJurusan(String? jurusan) {
    if (jurusan == null || jurusan.isEmpty) return const [];
    for (final item in data) {
      if (item.jurusan == jurusan) return item.lab;
    }
    return const [];
  }

  static const List<String> unitLainnya = [
    'Rektorat',
    'BAAK (Biro Administrasi Akademik)',
    'BAUK (Biro Administrasi Umum)',
    'Perpustakaan',
    'Pusat Komputer (PUSKOM)',
    'UPT Bahasa',
    'UPT Kewirausahaan',
    'Kantin / Koperasi',
    'PSDKU Kampus 2 Bondowoso',
    'PSDKU Kampus 3 Nganjuk',
    'PSDKU Kampus 4 Sidoarjo',
    'PSDKU Kampus 5 Ngawi',
    'PSDKU Kampus 6 Sabu Raijua',
    'Pihak Luar / Eksternal',
  ];

  static const List<String> commonCities = [
    'Bangkalan',
    'Banyuwangi',
    'Batu',
    'Blitar',
    'Bojonegoro',
    'Bondowoso',
    'Gresik',
    'Jember',
    'Jombang',
    'Kediri',
    'Lamongan',
    'Lumajang',
    'Madiun',
    'Magetan',
    'Malang',
    'Mojokerto',
    'Nganjuk',
    'Ngawi',
    'Pacitan',
    'Pamekasan',
    'Pasuruan',
    'Ponorogo',
    'Probolinggo',
    'Sampang',
    'Sidoarjo',
    'Sumenep',
    'Surabaya',
    'Trenggalek',
    'Tuban',
    'Tulungagung',
  ];

  static const List<String> statusOptions = [
    'Mahasiswa',
    'Dosen',
    'Tenaga Pendidik',
    'Teknisi',
    'Office Boy (OB)',
    'Satpam',
    'Pihak Luar',
  ];

  static const List<String> alasanPengaduanOptions = [
    'Saya seorang saksi yang khawatir dengan keadaan Korban.',
    'Saya seorang korban yang memerlukan bantuan pemulihan.',
    'Saya ingin perguruan tinggi menindak tegas terlapor.',
    'Saya ingin satgas mendokumentasikan kejadiannya, meningkatkan keamanan kampus dari kekerasan seksual, dan memberi pelindungan bagi saya.',
    'Lainnya',
  ];

  static const List<String> timeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
  ];
}

