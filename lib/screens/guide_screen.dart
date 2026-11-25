import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/checklist_provider.dart';
import '../utils/constants.dart';

/// Halaman Panduan Siaga Bencana Gempa Bumi & Checklist Tas Siaga
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  /// Panggilan telepon darurat BNPB 117
  Future<void> _callEmergency(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat melakukan panggilan ke $number.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Siaga'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // 1. BANNER KONTAK DARURAT
          Card(
            color: Colors.red.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panggilan Darurat Bencana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'BNPB Hotline: 117',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () =>
                        _callEmergency(context, AppConstants.emergencyPhone),
                    child: const Text('Telepon'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. CHECKLIST TAS SIAGA BENCANA (SQLite)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tas Siaga Bencana (Checklist)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmResetChecklist(context, checklistProvider),
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kesiapan Perlengkapan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${checklistProvider.checkedCount} / ${checklistProvider.totalCount} Siap',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: checklistProvider.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        checklistProvider.progress == 1.0
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  ...checklistProvider.items.map((item) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      value: item.isChecked,
                      title: Text(
                        item.item,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: item.isChecked
                              ? Colors.grey
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                      onChanged: (val) {
                        checklistProvider.toggleItem(item);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. KESIAPSIAGAAN GEMPA (SEBELUM, SAAT, SETELAH)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Langkah Kesiapsiagaan Gempa',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.blue),
              title: const Text(
                'Sebelum Terjadi Gempa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Langkah pencegahan dan persiapan dini',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuidePoint(
                        number: '1',
                        title: 'Amankan Perabotan Berat',
                        desc:
                            'Kencangkan lemari, rak buku, dan pemanas air ke dinding agar tidak mudah roboh saat gempa.',
                      ),
                      _GuidePoint(
                        number: '2',
                        title: 'Kenali Jalur Evakuasi',
                        desc:
                            'Ketahui jalur evakuasi dan titik kumpul (assembly point) di rumah, kantor, atau kampus.',
                      ),
                      _GuidePoint(
                        number: '3',
                        title: 'Siapkan Tas Siaga Bencana',
                        desc:
                            'Letakkan tas siaga di tempat yang mudah dijangkau dekat pintu keluar rumah.',
                      ),
                      _GuidePoint(
                        number: '4',
                        title: 'Ketahui Letak Sakelar Utama',
                        desc:
                            'Pastikan seluruh anggota keluarga mengetahui cara mematikan listrik, gas kompor, dan air.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text(
                'Saat Terjadi Gempa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Tindakan perlindungan diri segera',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuidePoint(
                        number: '1',
                        title: 'Drop, Cover, Hold On!',
                        desc:
                            'Merunduk ke lantai, lindungi kepala dan leher di bawah meja kokoh, dan berpegangan erat.',
                      ),
                      _GuidePoint(
                        number: '2',
                        title: 'Jauhi Kaca dan Jendela',
                        desc:
                            'Hindari pecahan kaca jendela, cermin, lampu gantung, atau benda yang berpotensi jatuh.',
                      ),
                      _GuidePoint(
                        number: '3',
                        title: 'Jangan Gunakan Lift',
                        desc:
                            'Selalu gunakan tangga darurat. Jika sedang di dalam lift, tekan semua tombol lantai dan segera keluar.',
                      ),
                      _GuidePoint(
                        number: '4',
                        title: 'Di Luar Ruangan: Menjauh dari Gedung',
                        desc:
                            'Cari tempat terbuka, jauhi tiang listrik, papan reklame, pohon tinggi, dan jembatan penyeberangan.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.healing_rounded, color: Colors.green),
              title: const Text(
                'Setelah Terjadi Gempa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Evakuasi tertib & antisipasi gempa susulan',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GuidePoint(
                        number: '1',
                        title: 'Waspada Gempa Susulan (Aftershocks)',
                        desc:
                            'Tetap waspada terhadap kemungkinan gempa susulan yang masih bisa merusak struktur bangunan.',
                      ),
                      _GuidePoint(
                        number: '2',
                        title: 'Periksa Kebocoran Gas & Kabel Listrik',
                        desc:
                            'Jangan menyalakan korek api atau sakelar listrik jika mencium bau gas yang bocor.',
                      ),
                      _GuidePoint(
                        number: '3',
                        title: 'Pantau Info Resmi BMKG',
                        desc:
                            'Dengarkan informasi terkini dari radio, aplikasi SiagaBumi, atau situs resmi BMKG & BNPB.',
                      ),
                      _GuidePoint(
                        number: '4',
                        title: 'Tinggalkan Pantai jika Ada Peringatan Tsunami',
                        desc:
                            'Jika gempa terasa kuat dan ada peringatan tsunami, segera lari ke tempat tinggi dengan segera.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. EDUKASI MAGNITUDO, KEDALAMAN & LEGENDA WARNA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Edukasi & Legenda Warna',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legenda Warna Magnitudo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  _buildLegendRow(
                    color: AppConstants.magLow,
                    label: '< 4.0 (Ringan)',
                    desc: 'Jarang dirasakan, terekam seismograf.',
                  ),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                    color: AppConstants.magMedium,
                    label: '4.0 - 4.9 (Sedang)',
                    desc: 'Dirasakan di dalam ruangan, barang bergoyang.',
                  ),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                    color: AppConstants.magHigh,
                    label: '5.0 - 5.9 (Kuat)',
                    desc: 'Dapat menimbulkan kerusakan ringan pada bangunan.',
                  ),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                    color: AppConstants.magSevere,
                    label: '>= 6.0 (Sangat Kuat / Signifikan)',
                    desc: 'Dapat merusak parah dan berpotensi memicu tsunami.',
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'Klasifikasi Kedalaman Gempa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Gempa Dangkal (< 60 km): Paling berbahaya karena pusat guncangan dekat dengan permukaan bumi.\n'
                    '• Gempa Menengah (60 - 300 km): Dampak kerusakan umumnya sedang.\n'
                    '• Gempa Dalam (> 300 km): Jarang menimbulkan kerusakan signifikan di permukaan.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResetChecklist(
      BuildContext context, ChecklistProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Checklist?'),
        content: const Text(
          'Semua status centang tas siaga bencana akan dikembalikan ke kondisi belum dicentang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.resetAll();
    }
  }
}

class _GuidePoint extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _GuidePoint({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
