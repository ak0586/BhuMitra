import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/saved_plots_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:bhumitra/core/localization_data.dart';
import 'package:bhumitra/core/localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_manager.dart';

class SavedPlotsScreen extends ConsumerStatefulWidget {
  const SavedPlotsScreen({super.key});

  @override
  ConsumerState<SavedPlotsScreen> createState() => _SavedPlotsScreenState();
}

class _SavedPlotsScreenState extends ConsumerState<SavedPlotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  void _loadBannerAd() {
    _bannerAd = AdManager().loadBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
  }

  void _loadNativeAd() {
    _nativeAd = AdManager().loadNativeAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isNativeAdLoaded = false;
            _nativeAd?.dispose();
            _nativeAd = null;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Lazy load saved plots only when this screen is opened
    Future.microtask(() => ref.read(savedPlotsProvider.notifier).loadPlots());
    _loadBannerAd();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPlots = ref.watch(savedPlotsProvider);

    // Filter plots based on search query
    final plots = _searchQuery.isEmpty
        ? allPlots
        : allPlots.where((plot) {
            final query = _searchQuery.toLowerCase();
            return plot.name.toLowerCase().contains(query) ||
                plot.location.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text('saved_plots'.tr(ref)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          if (allPlots.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          // Plot List or Empty State
          Expanded(
            child: plots.isEmpty
                ? _buildEmptyState(context, _searchQuery.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Add +1 to item count if native ad is loaded
                    itemCount:
                        plots.length +
                        (_isNativeAdLoaded && _nativeAd != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show ad at index 2 (after 2nd plot) or at the end if fewer than 2 items
                      if (_isNativeAdLoaded &&
                          _nativeAd != null &&
                          index == 2) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 120, // Adjust based on template style
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AdWidget(ad: _nativeAd!),
                        );
                      }

                      // Calculate actual plot index
                      // If we are past the ad index (2), subtract 1 from the list index
                      final plotIndex =
                          (_isNativeAdLoaded && _nativeAd != null && index > 2)
                          ? index - 1
                          : index;

                      // Safety check for bounds
                      if (plotIndex >= plots.length) return const SizedBox();

                      return _PlotCard(plot: plots[plotIndex]);
                    },
                  ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty illustration
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isSearching ? '🔍' : '📭',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              isSearching ? 'No Plots Found' : 'No Saved Plots Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isSearching
                  ? 'No saved plot with name "${_searchQuery}"\nTry searching with a different name or location'
                  : 'Start measuring your land to save plots and access them anytime',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 32),

            if (!isSearching)
              ElevatedButton.icon(
                onPressed: () => context.push('/boundary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Measure New Land'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlotCard extends ConsumerWidget {
  final SavedPlot plot;

  const _PlotCard({required this.plot});

  pw.Widget _buildVectorMap(List<List<double>> coordinates) {
    if (coordinates.isEmpty) {
      return pw.Container(
        height: 200,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          color: PdfColors.grey100,
        ),
        child: pw.Text('No map data available'),
      );
    }

    // Calculate bounds
    double minLat = coordinates[0][0];
    double maxLat = coordinates[0][0];
    double minLon = coordinates[0][1];
    double maxLon = coordinates[0][1];

    for (var coord in coordinates) {
      if (coord[0] < minLat) minLat = coord[0];
      if (coord[0] > maxLat) maxLat = coord[0];
      if (coord[1] < minLon) minLon = coord[1];
      if (coord[1] > maxLon) maxLon = coord[1];
    }

    final latRange = maxLat - minLat;
    final lonRange = maxLon - minLon;

    // Add padding
    final padding = 0.1;
    minLat -= latRange * padding;
    maxLat += latRange * padding;
    minLon -= lonRange * padding;
    maxLon += lonRange * padding;

    final adjustedLatRange = maxLat - minLat;
    final adjustedLonRange = maxLon - minLon;

    return pw.Container(
      height: 200,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey50,
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints!.maxWidth;
                final height = constraints.maxHeight;

                final points = coordinates.map((coord) {
                  final x = ((coord[1] - minLon) / adjustedLonRange) * width;
                  final y =
                      height -
                      ((coord[0] - minLat) / adjustedLatRange) * height;
                  return [x, y];
                }).toList();

                return pw.CustomPaint(
                  painter: (canvas, size) {
                    canvas.setFillColor(PdfColor.fromHex('#66BB6A'));
                    canvas.moveTo(points[0][0], points[0][1]);
                    for (int i = 1; i < points.length; i++) {
                      canvas.lineTo(points[i][0], points[i][1]);
                    }
                    canvas.closePath();
                    canvas.fillPath();

                    canvas.setStrokeColor(PdfColor.fromHex('#2E7D32'));
                    canvas.setLineWidth(2);
                    canvas.moveTo(points[0][0], points[0][1]);
                    for (int i = 1; i < points.length; i++) {
                      canvas.lineTo(points[i][0], points[i][1]);
                    }
                    canvas.closePath();
                    canvas.strokePath();

                    for (int i = 0; i < points.length; i++) {
                      canvas.setFillColor(PdfColors.white);
                      canvas.drawEllipse(points[i][0], points[i][1], 4, 4);
                      canvas.fillPath();

                      canvas.setFillColor(PdfColor.fromHex('#FF3B30'));
                      canvas.drawEllipse(points[i][0], points[i][1], 2.5, 2.5);
                      canvas.fillPath();
                    }
                  },
                );
              },
            ),
          ),
          // Add point number labels
          pw.LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints!.maxWidth;
              final height = constraints.maxHeight;

              return pw.Stack(
                children: coordinates.asMap().entries.map((entry) {
                  final i = entry.key;
                  final coord = entry.value;
                  final x = ((coord[1] - minLon) / adjustedLonRange) * width;
                  final y =
                      height -
                      ((coord[0] - minLat) / adjustedLatRange) * height;

                  return pw.Positioned(
                    left: x + 6,
                    top: y - 6,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(1.5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildAreaTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Future<void> _sharePlot(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

      // No need to generate screenshot - using vector map instead

      final pdf = pw.Document();

      // First Page - Header and Area Measurements
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2E7D32'),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BhuMitra',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        plot.name,
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Area: ${plot.area}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Location: ${plot.location}'),
                pw.SizedBox(height: 8),
                pw.Text('Date: ${plot.date}'),

                // Custom unit if available
                if (plot.customUnitName != null &&
                    plot.customUnitValue != null &&
                    plot.customUnitBase != null) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Custom Local Unit',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#2E7D32'),
                        width: 2,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          plot.customUnitName!,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          'See area table below',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2E7D32'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 24),

                // Area Measurements Table
                pw.Text(
                  'Area Measurements',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Parse square meters from plot.area string (format: "X.XX sq m")
                pw.Builder(
                  builder: (context) {
                    // Extract square meters value from the area string
                    final sqMString = plot.area.split(' ')[0];
                    final sqM = double.tryParse(sqMString) ?? 0.0;

                    // Calculate all units from square meters
                    final sqFt = sqM * 10.76391042;
                    final sqYd = sqM * 1.19599005;
                    final acre = sqM * 0.00024710538;
                    final hectare = sqM * 0.0001;

                    // Calculate custom unit if available
                    String? customUnitDisplayValue;
                    if (plot.customUnitName != null &&
                        plot.customUnitValue != null &&
                        plot.customUnitBase != null) {
                      final conversionFactors = {
                        'Square Meters': 1.0,
                        'Square Feet': 10.76391042,
                        'Square Yards': 1.19599005,
                        'Acre': 0.00024710538,
                        'Hectare': 0.0001,
                      };
                      final baseUnitValue =
                          sqM * (conversionFactors[plot.customUnitBase] ?? 1.0);
                      final customValue = baseUnitValue / plot.customUnitValue!;
                      customUnitDisplayValue = customValue.toStringAsFixed(2);
                    }

                    return pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#E8F5E9'),
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Unit',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Value',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildAreaTableRow(
                          'Square Feet',
                          sqFt.toStringAsFixed(2),
                        ),
                        _buildAreaTableRow(
                          'Square Meters',
                          sqM.toStringAsFixed(2),
                        ),
                        _buildAreaTableRow(
                          'Square Yards',
                          sqYd.toStringAsFixed(2),
                        ),
                        _buildAreaTableRow('Acre', acre.toStringAsFixed(4)),
                        _buildAreaTableRow(
                          'Hectare',
                          hectare.toStringAsFixed(4),
                        ),
                        // Add custom unit if available
                        if (customUnitDisplayValue != null)
                          _buildAreaTableRow(
                            plot.customUnitName!,
                            customUnitDisplayValue,
                          ),
                      ],
                    );
                  },
                ),

                pw.Spacer(),
                pw.Text(
                  'Continued on next page...',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );

      // Second Page - Visual Map and Coordinates
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Land Boundary Map (Vector)
                pw.Text(
                  'Land Boundary Map',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildVectorMap(plot.coordinates),

                pw.SizedBox(height: 24),
                pw.Text(
                  'Boundary Coordinates',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Point',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Latitude',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Longitude',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(
                      plot.coordinates.length,
                      (index) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              plot.coordinates[index][0].toStringAsFixed(6),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              plot.coordinates[index][1].toStringAsFixed(6),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated by BhuMitra - Land Area Measurement App',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/${plot.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: plot.name,
        text: 'Land measurement report for ${plot.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF shared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Map thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(painter: _MiniMapPainter()),
                ),

                const SizedBox(width: 16),

                // Plot info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plot.area,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).iconTheme.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plot.location,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plot.date,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.push('/plot-view', extra: plot),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _sharePlot(context, ref),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Plot'),
                        content: const Text(
                          'Are you sure you want to delete this plot?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(savedPlotsProvider.notifier)
                                  .deletePlot(plot.id);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);

    // Draw pins
    final pinPaint = Paint()..color = const Color(0xFFFF3B30);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 4, pinPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 4, pinPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.8), 4, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
