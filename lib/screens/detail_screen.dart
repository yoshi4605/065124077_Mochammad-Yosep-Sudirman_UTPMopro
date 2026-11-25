import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/earthquake.dart';
import '../providers/watchlist_provider.dart';
import '../utils/formatters.dart';
import '../widgets/magnitude_badge.dart';

/// Halaman Detail Lengkap Gempa Bumi
class DetailScreen extends StatefulWidget {
  final Earthquake earthquake;

  const DetailScreen({super.key, required this.earthquake});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Earthquake _earthquake;

  @override
  void initState() {
    super.initState();
    _earthquake = widget.earthquake;
  }

  /// Membuka lokasi gempa di Google Maps via url_launcher
  Future<void> _openMap() async {
    final url = _earthquake.googleMapsUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat lokasi gempa tidak valid.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka aplikasi Google Maps.')),
        );
      }
    }
  }

  /// Membagikan informasi gempa via share_plus
  void _shareEarthquake() {
    Share.share(
      _earthquake.shareText,
      subject: 'Informasi Gempa BMKG - ${_earthquake.wilayah}',
    );
  }

  /// Menampilkan dialog tambah/edit catatan saat menyimpan
  Future<void> _showAddNoteDialog(BuildContext context, WatchlistProvider provider) async {
    final noteController = TextEditingController(text: _earthquake.catatan ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan ke Pantauan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambahkan catatan pribadi untuk gempa ini (opsional):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Contoh: Gempa terasa saat di kantor lt. 3, lampu bergoyang.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await provider.addToWatchlist(_earthquake, catatan: result);
      if (!context.mounted) return;
      if (success) {
        setState(() {
          _earthquake = _earthquake.copyWith(catatan: result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gempa berhasil disimpan ke Pantauan Saya.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Menghapus gempa dari pantauan
  Future<void> _removeFromWatchlist(WatchlistProvider provider) async {
    final removed = await provider.removeFromWatchlist(_earthquake.id);
    if (mounted && removed != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gempa dihapus dari pantauan.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Batal',
            onPressed: () {
              provider.addToWatchlist(removed, catatan: removed.catatan);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchlistProvider = Provider.of<WatchlistProvider>(context);
    final isSaved = watchlistProvider.isSaved(_earthquake.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Gempa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan Info Gempa',
            onPressed: _shareEarthquake,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Kartu Utama
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MagnitudeBadge(
                          magnitude: _earthquake.magnitudeValue,
                          isLarge: true,
                          heroTag: 'mag-${_earthquake.id}',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.getMagnitudeCategory(
                                    _earthquake.magnitudeValue),
                                style: TextStyle(
                                  color: Formatters.getMagnitudeColor(
                                      _earthquake.magnitudeValue),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _earthquake.wilayah,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // Informasi Detail Grid
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today_rounded,
                      label: 'Waktu Gempa',
                      value: Formatters.formatIndonesianDate(
                        _earthquake.tanggal,
                        _earthquake.jam,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.straighten_rounded,
                      label: 'Kedalaman Sumber',
                      value: _earthquake.kedalaman,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_rounded,
                      label: 'Koordinat Titik',
                      value:
                          '${_earthquake.coordinates} (${_earthquake.lintang}, ${_earthquake.bujur})',
                    ),
                    if (_earthquake.potensi != null &&
                        _earthquake.potensi!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        icon: Icons.shield_rounded,
                        label: 'Potensi Tsunami',
                        value: _earthquake.potensi!,
                        isHighlight: _earthquake.hasTsunamiPotential,
                      ),
                    ],
                    if (_earthquake.dirasakan != null &&
                        _earthquake.dirasakan!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        icon: Icons.vibration_rounded,
                        label: 'Wilayah Dirasakan (MMI)',
                        value: _earthquake.dirasakan!,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Catatan Pribadi (Jika Tersimpan)
            if (isSaved) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Catatan Pribadi Anda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _showAddNoteDialog(context, watchlistProvider),
                              tooltip: 'Ubah Catatan',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (_earthquake.catatan != null &&
                                  _earthquake.catatan!.isNotEmpty)
                              ? _earthquake.catatan!
                              : '(Belum ada catatan. Sentuh ikon pensil untuk menambahkan.)',
                          style: TextStyle(
                            fontStyle: (_earthquake.catatan == null ||
                                    _earthquake.catatan!.isEmpty)
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Tombol Aksi Cepat (Simpan & Peta)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: isSaved
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                _removeFromWatchlist(watchlistProvider),
                            icon: const Icon(Icons.bookmark_remove_rounded),
                            label: const Text('Hapus Pantauan'),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                _showAddNoteDialog(context, watchlistProvider),
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: const Text('Simpan ke Pantauan'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _openMap,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Buka di Peta'),
                    ),
                  ),
                ],
              ),
            ),

            // Gambar Shakemap BMKG (Jika Ada)
            if (_earthquake.fullShakemapUrl != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Peta Guncangan (Shakemap BMKG)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: _earthquake.fullShakemapUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey.shade100,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Peta guncangan (shakemap) tidak dapat dimuat atau belum tersedia dari server BMKG.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlight ? Colors.red : theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isHighlight ? Colors.red.shade900 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
