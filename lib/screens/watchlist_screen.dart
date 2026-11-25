import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/earthquake.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/earthquake_card.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'detail_screen.dart';

/// Halaman Pantauan Saya: Data gempa tersimpan di SQLite lokal dengan catatan pribadi
class WatchlistScreen extends StatelessWidget {
  final VoidCallback onNavigateToHome;

  const WatchlistScreen({super.key, required this.onNavigateToHome});

  /// Dialog untuk mengedit catatan pribadi
  Future<void> _editNoteDialog(
      BuildContext context, WatchlistProvider provider, Earthquake earthquake) async {
    final controller = TextEditingController(text: earthquake.catatan ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Catatan Gempa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              earthquake.wilayah,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan kejadian gempa...',
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
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.updateNote(earthquake.id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan pribadi berhasil diperbarui.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistProvider = Provider.of<WatchlistProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantauan Saya'),
      ),
      body: _buildBody(context, watchlistProvider, theme),
    );
  }

  Widget _buildBody(
      BuildContext context, WatchlistProvider provider, ThemeData theme) {
    if (provider.isLoading && provider.watchlist.isEmpty) {
      return const LoadingView(message: 'Memuat data pantauan lokal...');
    }

    if (provider.errorMessage != null && provider.watchlist.isEmpty) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadWatchlist(),
      );
    }

    final list = provider.watchlist;

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadWatchlist(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: EmptyView(
                icon: Icons.bookmark_border_rounded,
                title: 'Belum Ada Gempa Dipantau',
                message:
                    'Simpan gempa dari halaman Beranda atau Daftar Gempa untuk memantau data dan menambahkan catatan pribadi.',
                action: FilledButton.icon(
                  onPressed: onNavigateToHome,
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text('Jelajahi Gempa'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${list.length} Gempa Tersimpan',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Geser untuk menghapus',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadWatchlist(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: list.length,
              itemBuilder: (context, index) {
              final eq = list[index];

              return Dismissible(
                key: Key('watchlist-${eq.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete_rounded, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus dari Pantauan?'),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus gempa di "${eq.wilayah}" dari daftar pantauan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  final removed = await provider.removeFromWatchlist(eq.id);
                  if (context.mounted && removed != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gempa di "${eq.wilayah}" dihapus.'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            provider.addToWatchlist(removed,
                                catatan: removed.catatan);
                          },
                        ),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    EarthquakeCard(
                      earthquake: eq,
                      showNote: true,
                      onCustomTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(earthquake: eq),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 14,
                      right: 24,
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Edit Catatan',
                        onPressed: () =>
                            _editNoteDialog(context, provider, eq),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
  }
}
