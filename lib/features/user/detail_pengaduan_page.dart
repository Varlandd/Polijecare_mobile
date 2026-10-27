import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_url.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/user_portal_service.dart';
import 'user_shell_page.dart';

/// Halaman Detail Pengaduan (`/user/histori-pengaduan/:id`)
/// — port 1:1 dari `pages/user/detail-pengaduan.jsx`.
class DetailPengaduanPage extends StatefulWidget {
  const DetailPengaduanPage({
    super.key,
    required this.complaintId,
  });

  final int complaintId;

  @override
  State<DetailPengaduanPage> createState() => _DetailPengaduanPageState();
}

class _DetailPengaduanPageState extends State<DetailPengaduanPage> {
  UserComplaint? _complaint;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final res =
        await UserPortalService.instance.getDetailPengaduan(widget.complaintId);
    if (!mounted) return;
    setState(() {
      _complaint = res;
      _loading = false;
    });
  }

  int _activeStepIndex(UserComplaint c) {
    if (c.status == 'completed') return 3;
    if (c.status == 'rejected') return 2;
    if (c.schedules.isNotEmpty) {
      final s = c.schedules.first.status;
      if (s == 'completed') return 3;
      if (s == 'rejected' || s == 'cancelled') return 2;
      if (s == 'approved') return 1;
      if (s == 'pending') return 0;
    }
    if (c.status == 'approved') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = _complaint;

    return UserShellPage(
      title: c != null
          ? 'Laporan #${c.reportReference}'
          : 'Detail Laporan #${widget.complaintId}',
      subtitle: 'Detail perkembangan penanganan pengaduan',
      activePath: AppRoutes.userHistoriPengaduan,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            )
          : c == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: Color(0xFFF87171),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Laporan Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kembali ke Histori'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Back Navigation + Urgency Badge ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context).pop(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: AppColors.gray200),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 16,
                                    color: AppColors.gray600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Kembali ke Daftar',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _UrgencyBadge(urgency: c.urgencyLevel),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Main Card ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.gray100),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── 4-Step Visual Status Stepper ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 22),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAFAFA),
                                border: Border(
                                    bottom:
                                        BorderSide(color: AppColors.gray100)),
                              ),
                              child: _StatusStepper(
                                activeIdx: _activeStepIndex(c),
                              ),
                            ),

                            // ── Title & Status Section ──
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.gray100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'REF: ${c.reportReference}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                      ),
                                      _StatusBadge(status: c.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    c.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray900,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: AppColors.gray500,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            DateFormat('dd MMMM yyyy, HH:mm')
                                                .format(c.createdAt),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.gray500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_offer_outlined,
                                            size: 14,
                                            color: AppColors.gray500,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            c.categoryName,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.gray500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  if (c.status == 'rejected' &&
                                      c.rejectionReason != null &&
                                      c.rejectionReason!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFFFE4E6)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ALASAN PENOLAKAN / JADWALKAN ULANG',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF9F1239),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '"${c.rejectionReason}"',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF881337),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // ── Jadwal Sesi Penanganan ──
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(
                                        color: AppColors.gray100, height: 1),
                                  ),
                                  const Text(
                                    'JADWAL SESI PENANGANAN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray500,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (c.schedules.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray50,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.gray200),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: AppColors.gray400,
                                            size: 24,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Laporan Anda sedang menunggu antrean untuk dijadwalkan penanganan oleh Tim Satgas.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.gray500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (int i = 0;
                                            i < c.schedules.length;
                                            i++) ...[
                                          _ScheduleSessionBox(
                                            sessionNumber:
                                                c.schedules.length - i,
                                            schedule: c.schedules[i],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            const Divider(color: AppColors.gray100, height: 1),

                            // ── Detail Utama & Kronologi ──
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray50,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: AppColors.gray100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _DetailMetaRow(
                                          label: 'KATEGORI KEKERASAN',
                                          value: c.categoryName,
                                          icon: Icons.shield_outlined,
                                          iconColor: const Color(0xFF8B5CF6),
                                        ),
                                        const SizedBox(height: 12),
                                        _DetailMetaRow(
                                          label: 'LOKASI KEJADIAN',
                                          value: c.location,
                                          icon: Icons.location_on_outlined,
                                          iconColor: const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(height: 12),
                                        _DetailMetaRow(
                                          label: 'KOORDINAT GPS',
                                          value: (c.latitude != null &&
                                                  c.longitude != null)
                                              ? '${c.latitude}, ${c.longitude}'
                                              : 'Tidak dilampirkan',
                                          icon: Icons.my_location_rounded,
                                          iconColor: AppColors.gray500,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Kronologi Rinci
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.subject_rounded,
                                        size: 18,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Kronologi Rinci',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray50,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: AppColors.gray100),
                                    ),
                                    child: Text(
                                      c.chronology.isNotEmpty
                                          ? c.chronology
                                          : 'Tidak ada rincian kronologi yang dilampirkan.',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.gray700,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),

                                  // Perkembangan Penanganan (Notes Timeline)
                                  if (c.schedules.any((s) =>
                                      (s.keteranganPihak?.isNotEmpty ??
                                          false) ||
                                      (s.feedbackNotes?.isNotEmpty ?? false) ||
                                      (s.saranKonselor?.isNotEmpty ??
                                          false))) ...[
                                    const SizedBox(height: 24),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.sync_rounded,
                                          size: 18,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Perkembangan Penanganan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    for (final note in c.schedules.where((s) =>
                                        (s.keteranganPihak?.isNotEmpty ??
                                            false) ||
                                        (s.feedbackNotes?.isNotEmpty ??
                                            false) ||
                                        (s.saranKonselor?.isNotEmpty ??
                                            false)))
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                              color: AppColors.gray200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFEEF2FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    note.counseleeType ==
                                                            'pelapor'
                                                        ? 'SESI KORBAN'
                                                        : 'SESI PENANGANAN',
                                                    style: const TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.indigo600,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  note.tanggal,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.gray400,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Ditangani oleh: ${note.counselorName ?? 'Tim Satgas'}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.gray900,
                                              ),
                                            ),
                                            if ((note.keteranganPihak ??
                                                    note.feedbackNotes) !=
                                                null) ...[
                                              const SizedBox(height: 10),
                                              const Text(
                                                'HASIL SESI / KETERANGAN:',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.gray400,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.gray50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  note.keteranganPihak ??
                                                      note.feedbackNotes ??
                                                      '',
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: AppColors.gray700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (note.saranKonselor != null &&
                                                note.saranKonselor!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFAF5FF),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFF3E8FF),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'SARAN & TINDAK LANJUT:',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF8B5CF6),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      note.saranKonselor!,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF581C87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                  ],

                                  // Lampiran Bukti
                                  if (c.attachments.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      'Lampiran Bukti (${c.attachments.length})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    for (final att in c.attachments)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.gray50,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: AppColors.gray200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.link_rounded,
                                              color: AppColors.indigo600,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                att.fileName,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final url = getStorageUrl(
                                                      att.filePath,
                                                    ) ??
                                                    '';
                                                if (url.isNotEmpty) {
                                                  AppLauncher.openUrl(url);
                                                }
                                              },
                                              child: const Text('BUKA'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],

                                  // Informasi Korban & Metadata Teknis
                                  const SizedBox(height: 24),
                                  const Text(
                                    'INFORMASI KORBAN & METADATA TEKNIS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray500,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray50,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          Border.all(color: AppColors.gray100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Status Laporan (Tipe Korban)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.victimType == 'self'
                                              ? 'Korban Melaporkan Diri Sendiri'
                                              : 'Dilaporkan Oleh Orang Lain (Saksi)',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                        if (c.victimType == 'other') ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Nama Korban: ${c.victimName ?? '-'} (${c.victimRelationship ?? '-'})',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Text(
                                          'Tim Satgas Bertugas: ${c.counselorName ?? 'Dalam antrean plotting'}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.activeIdx});

  final int activeIdx;

  static const _steps = [
    ('Peninjauan\nLaporan', Color(0xFFF59E0B)),
    ('Sedang\nDitangani', Color(0xFF3B82F6)),
    ('Jadwalkan\nUlang', Color(0xFFFB7185)),
    ('Laporan\nSelesai', Color(0xFF10B981)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: i <= activeIdx ? _steps[i].$2 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          i <= activeIdx ? _steps[i].$2 : AppColors.gray200,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: i < activeIdx
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: i <= activeIdx
                                ? Colors.white
                                : AppColors.gray400,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  _steps[i].$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: i <= activeIdx
                        ? AppColors.gray900
                        : AppColors.gray400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        label = 'SEDANG DITANGANI';
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        break;
      case 'completed':
        label = 'SELESAI';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'rejected':
        label = 'JADWALKAN ULANG';
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFF9F1239);
        break;
      default:
        label = 'SEDANG DITINJAU';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.urgency});
  final String urgency;

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;
    switch (urgency.toLowerCase()) {
      case 'high':
      case 'tinggi':
        label = 'Tinggi';
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case 'medium':
      case 'sedang':
        label = 'Sedang';
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      default:
        label = 'Rendah';
        bg = AppColors.gray200;
        fg = AppColors.gray700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _ScheduleSessionBox extends StatelessWidget {
  const _ScheduleSessionBox({
    required this.sessionNumber,
    required this.schedule,
  });

  final int sessionNumber;
  final CounselingScheduleItem schedule;

  @override
  Widget build(BuildContext context) {
    final isCompleted = schedule.status == 'completed';
    final isOnline = schedule.metode.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$sessionNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sesi Penanganan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? 'SELESAI' : 'TERJADWAL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tanggal: ${schedule.tanggal} • ${schedule.jamMulaiShort} – ${schedule.jamSelesaiShort} WIB',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.gray700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isOnline ? 'Online' : 'Offline'}: ${isOnline ? (schedule.meetingLink ?? 'Link menyusul') : (schedule.lokasi ?? '-')}',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Satgas: ${schedule.counselorName ?? 'Satgas PPKPT'}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetaRow extends StatelessWidget {
  const _DetailMetaRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: AppColors.gray400,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

