import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/saved_plots_provider.dart';
import '../../core/preferences.dart';
import '../../core/location_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AreaResultScreen extends ConsumerStatefulWidget {
  const AreaResultScreen({super.key});

  @override
  ConsumerState<AreaResultScreen> createState() => _AreaResultScreenState();
}

class _AreaResultScreenState extends ConsumerState<AreaResultScreen> {
  // Controllers for custom unit inputs
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _conversionValueController =
      TextEditingController();

  String _selectedBaseUnit = 'Square Feet';
  String _selectedDisplayUnit = 'Square Feet';
  double? _customCalculatedArea;

  // Get area from provider
  double get _totalAreaSqM {
    final result = ref.watch(areaResultProvider);
    return result?.squareMeters ?? 0.0;
  }

  // Conversion factors from square meters
  static const Map<String, double> _conversionFactors = {
    'Square Meters': 1.0,
    'Square Feet': 10.76391042,
    'Square Yards': 1.19599005,
    'Acre': 0.00024710538,
    'Hectare': 0.0001,
  };

  // State for navigation and saving
  bool _hasManuallySaved = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    // Load default unit from settings
    _selectedDisplayUnit = ref.read(defaultUnitProvider);
    _loadSavedCustomUnit();
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _conversionValueController.dispose();
    super.dispose();
  }

  // Load saved custom unit from SharedPreferences
  Future<void> _loadSavedCustomUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('custom_unit_name');
    final savedValue = prefs.getDouble('custom_unit_value');
    final savedBase = prefs.getString('custom_unit_base');

    if (savedName != null && savedValue != null && savedBase != null) {
      setState(() {
        _unitNameController.text = savedName;
        _conversionValueController.text = savedValue.toString();
        _selectedBaseUnit = savedBase;
      });
    }
  }

  // Save custom unit to SharedPreferences
  Future<void> _saveCustomUnit() async {
    if (_unitNameController.text.isEmpty ||
        _conversionValueController.text.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_unit_name', _unitNameController.text);
    await prefs.setDouble(
      'custom_unit_value',
      double.parse(_conversionValueController.text),
    );
    await prefs.setString('custom_unit_base', _selectedBaseUnit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom unit saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  double _getAreaInUnit(String unit) {
    return _totalAreaSqM * _conversionFactors[unit]!;
  }

  void _calculateCustomArea() {
    final valueText = _conversionValueController.text;
    if (valueText.isEmpty || _unitNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final conversionValue = double.tryParse(valueText);
    if (conversionValue == null || conversionValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    // Get area in the selected base unit
    final areaInBaseUnit = _getAreaInUnit(_selectedBaseUnit);

    // Calculate area in custom unit
    // If 1 Custom Unit = X Base Units, then Total Custom Units = Total Base Units / X
    final customArea = areaInBaseUnit / conversionValue;

    setState(() {
      _customCalculatedArea = customArea;
    });

    // Save the custom unit
    _saveCustomUnit();
  }

  Future<void> _savePlot() async {
    final areaResult = ref.read(areaResultProvider);
    if (areaResult == null) return;

    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Plot'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Plot Name',
            hintText: 'e.g., North Field',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.pop(dialogContext);

              // Show loading indicator
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saving plot...')));
              }

              try {
                // Get location address for the first point
                String location = 'Unknown Location';
                if (areaResult.coordinates.isNotEmpty &&
                    areaResult.coordinates[0].isNotEmpty) {
                  try {
                    location = await LocationHelper.getAddressFromCoordinates(
                      areaResult.coordinates[0][0],
                      areaResult.coordinates[0][1],
                    );
                  } catch (e) {
                    print('Error getting address: $e');
                  }
                }

                final plot = SavedPlot(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  area: '${areaResult.squareMeters.toStringAsFixed(2)} sq m',
                  date: DateTime.now().toString().split(' ')[0],
                  location: location,
                  coordinates: areaResult.coordinates,
                  customUnitName: _unitNameController.text.isNotEmpty
                      ? _unitNameController.text
                      : null,
                  customUnitValue: _conversionValueController.text.isNotEmpty
                      ? double.tryParse(_conversionValueController.text)
                      : null,
                  customUnitBase: _unitNameController.text.isNotEmpty
                      ? _selectedBaseUnit
                      : null,
                );

                await ref.read(savedPlotsProvider.notifier).addPlot(plot);

                if (mounted) {
                  setState(() {
                    _hasManuallySaved = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plot saved successfully')),
                  );
                  // Navigate to saved plots
                  context.push('/saved');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving plot: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVectorMap(List<List<double>> coordinates) {
    if (coordinates.isEmpty) {
      return pw.Container(
        height: 250,
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
      height: 250,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey50,
      ),
      child: pw.Stack(
        children: [
          // Draw the polygon shape
          pw.Positioned.fill(
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints!.maxWidth;
                final height = constraints.maxHeight;

                // Transform coordinates
                final points = coordinates.map((coord) {
                  final x = ((coord[1] - minLon) / adjustedLonRange) * width;
                  final y =
                      height -
                      ((coord[0] - minLat) / adjustedLatRange) * height;
                  return [x, y];
                }).toList();

                return pw.CustomPaint(
                  painter: (canvas, size) {
                    // Draw filled polygon
                    canvas.setFillColor(PdfColor.fromHex('#66BB6A'));
                    canvas.moveTo(points[0][0], points[0][1]);
                    for (int i = 1; i < points.length; i++) {
                      canvas.lineTo(points[i][0], points[i][1]);
                    }
                    canvas.closePath();
                    canvas.fillPath();

                    // Draw border
                    canvas.setStrokeColor(PdfColor.fromHex('#2E7D32'));
                    canvas.setLineWidth(2);
                    canvas.moveTo(points[0][0], points[0][1]);
                    for (int i = 1; i < points.length; i++) {
                      canvas.lineTo(points[i][0], points[i][1]);
                    }
                    canvas.closePath();
                    canvas.strokePath();

                    // Draw points and numbers
                    for (int i = 0; i < points.length; i++) {
                      // White outer circle
                      canvas.setFillColor(PdfColors.white);
                      canvas.drawEllipse(points[i][0], points[i][1], 5, 5);
                      canvas.fillPath();

                      // Red inner circle
                      canvas.setFillColor(PdfColor.fromHex('#FF3B30'));
                      canvas.drawEllipse(points[i][0], points[i][1], 3, 3);
                      canvas.fillPath();

                      // Point number label (using text widget instead of drawString)
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
                    left: x + 7,
                    top: y - 7,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          fontSize: 8,
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

  Future<void> _generateAndSharePDF() async {
    final areaResult = ref.read(areaResultProvider);
    if (areaResult == null) return;

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      }

      // No need to generate screenshot - using vector map instead

      // Create PDF document
      final pdf = pw.Document();

      // First Page - Header and Area Measurements
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
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
                        'Land Measurement Report',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Date
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),

                pw.SizedBox(height: 24),

                // Area Measurements
                pw.Text(
                  'Area Measurements',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 16),

                // Table of measurements
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    _buildPdfTableRow('Unit', 'Value', isHeader: true),
                    _buildPdfTableRow(
                      'Square Feet',
                      areaResult.squareFeet.toStringAsFixed(2),
                    ),
                    _buildPdfTableRow(
                      'Square Meters',
                      areaResult.squareMeters.toStringAsFixed(2),
                    ),
                    _buildPdfTableRow(
                      'Square Yards',
                      areaResult.squareYards.toStringAsFixed(2),
                    ),
                    _buildPdfTableRow(
                      'Acre',
                      areaResult.acre.toStringAsFixed(4),
                    ),
                    _buildPdfTableRow(
                      'Hectare',
                      areaResult.hectare.toStringAsFixed(4),
                    ),
                    // Add custom unit if available
                    if (_customCalculatedArea != null &&
                        _unitNameController.text.isNotEmpty)
                      _buildPdfTableRow(
                        _unitNameController.text,
                        _customCalculatedArea!.toStringAsFixed(2),
                      ),
                  ],
                ),

                pw.SizedBox(height: 24),

                // Custom unit if available
                if (_customCalculatedArea != null &&
                    _unitNameController.text.isNotEmpty) ...[
                  pw.Text(
                    'Custom Local Unit',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
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
                          _unitNameController.text,
                          style: const pw.TextStyle(fontSize: 16),
                        ),
                        pw.Text(
                          _customCalculatedArea!.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2E7D32'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Land Boundary Map (Vector)
                pw.Text(
                  'Land Boundary Map',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildVectorMap(areaResult.coordinates),

                pw.SizedBox(height: 24),

                // Boundary Coordinates
                pw.Text(
                  'Boundary Coordinates',
                  style: pw.TextStyle(
                    fontSize: 20,
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
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Point',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Latitude',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Longitude',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(
                      areaResult.coordinates.length,
                      (index) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${index + 1}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              areaResult.coordinates[index][0].toStringAsFixed(
                                6,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              areaResult.coordinates[index][1].toStringAsFixed(
                                6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
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

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/land_measurement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Land Measurement Report',
        text: 'Here is the land measurement report from BhuMitra.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  pw.TableRow _buildPdfTableRow(
    String label,
    String value, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9'))
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 14 : 12,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAutoSave() async {
    // Check if auto-save is enabled
    final autoSave = ref.read(autoSaveProvider);
    debugPrint('Auto-save check: $autoSave');
    if (!autoSave) return;

    final areaResult = ref.read(areaResultProvider);
    if (areaResult == null) {
      debugPrint('Auto-save skipped: areaResult is null');
      return;
    }

    try {
      // Generate default name
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final name = 'Auto-Plot $formattedDate';

      // Get location address for the first point
      String location = 'Unknown Location';
      if (areaResult.coordinates.isNotEmpty &&
          areaResult.coordinates[0].isNotEmpty) {
        try {
          location = await LocationHelper.getAddressFromCoordinates(
            areaResult.coordinates[0][0],
            areaResult.coordinates[0][1],
          );
        } catch (e) {
          debugPrint('Error getting address for auto-save: $e');
        }
      }

      final plot = SavedPlot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        area: '${areaResult.squareMeters.toStringAsFixed(2)} sq m',
        date: formattedDate.split(' ')[0],
        location: location,
        coordinates: areaResult.coordinates,
      );

      await ref.read(savedPlotsProvider.notifier).addPlot(plot);
      debugPrint('Auto-save successful');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plot auto-saved'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-saving plot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBackNavigation() async {
    debugPrint(
      '_handleBackNavigation called. _hasManuallySaved: $_hasManuallySaved, autoSave: ${ref.read(autoSaveProvider)}',
    );
    // Check if auto-save is enabled and we haven't saved manually
    final autoSave = ref.read(autoSaveProvider);

    if (autoSave && !_hasManuallySaved) {
      // Show saving feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving plot before exit...'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      }

      await _handleAutoSave();
    }

    if (mounted) {
      setState(() {
        _canPop = true;
      });
      // Allow the pop to proceed
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          title: const Text('Area Calculation Result'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackNavigation(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Success Banner
              _buildSuccessBanner(),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Area Units Card
                    _buildPrimaryAreaCard(),

                    const SizedBox(height: 24),

                    // Custom Local Unit Section
                    _buildCustomLocalUnitSection(),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text(
            'Area Calculated Successfully',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAreaCard() {
    final displayArea = _getAreaInUnit(_selectedDisplayUnit);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Main Display Value
            // Main Display Value
            Text(
              displayArea.toStringAsFixed(ref.watch(precisionProvider)),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 8),

            // Unit Selector Dropdown
            DropdownButton<String>(
              value: _selectedDisplayUnit,
              isDense: true,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              underline: Container(),
              items: _conversionFactors.keys.map((String unit) {
                return DropdownMenuItem<String>(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDisplayUnit = newValue;
                  });
                }
              },
            ),

            const Divider(height: 32),

            // All Primary Units
            _buildPrimaryUnitRow('Square Feet', _getAreaInUnit('Square Feet')),
            const SizedBox(height: 12),
            _buildPrimaryUnitRow(
              'Square Meters',
              _getAreaInUnit('Square Meters'),
            ),
            const SizedBox(height: 12),
            _buildPrimaryUnitRow(
              'Square Yards',
              _getAreaInUnit('Square Yards'),
            ),
            const SizedBox(height: 12),
            _buildPrimaryUnitRow('Acre', _getAreaInUnit('Acre')),
            const SizedBox(height: 12),
            _buildPrimaryUnitRow('Hectare', _getAreaInUnit('Hectare')),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryUnitRow(String label, double value) {
    final precision = ref.watch(precisionProvider);
    final displayValue = value.toStringAsFixed(precision);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomLocalUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Local Unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unit Name Input
                TextField(
                  controller: _unitNameController,
                  decoration: InputDecoration(
                    labelText: 'Local Unit Name',
                    hintText: 'e.g., Bigha, Katha, Guntha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 16),

                // Conversion Factor Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _conversionValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '1 Local Unit =',
                          hintText: 'Value',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Base Unit Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedBaseUnit,
                        isExpanded: true, // Prevent overflow
                        decoration: InputDecoration(
                          labelText: 'Base Unit',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12, // Reduced vertical padding
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        isDense: true, // Reduce height
                        items: _conversionFactors.keys.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedBaseUnit = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Calculate Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _calculateCustomArea,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Calculate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Result Display
                if (_customCalculatedArea != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2E7D32),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Area in ${_unitNameController.text}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _customCalculatedArea!.toStringAsFixed(
                            ref.watch(precisionProvider),
                          ),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Plot Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _savePlot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.save),
            label: const Text(
              'Save Plot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Share PDF and Recalculate Buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _generateAndSharePDF,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Share PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleBackNavigation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Recalculate',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
