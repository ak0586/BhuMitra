import 'package:bhumitra/core/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitConverterScreen extends ConsumerStatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  ConsumerState<UnitConverterScreen> createState() =>
      _UnitConverterScreenState();
}

class _UnitConverterScreenState extends ConsumerState<UnitConverterScreen> {
  String _fromUnit = 'Square Feet';
  String _toUnit = 'Square Meters';
  final TextEditingController _inputController = TextEditingController();
  double? _result;
  Map<String, double>? _allConversions;

  final List<String> _units = [
    'Square Feet',
    'Square Meters',
    'Square Yards',
    'Acre',
    'Hectare',
  ];

  // Conversion factors to square feet
  final Map<String, double> _toSqFt = {
    'Square Feet': 1.0,
    'Square Meters': 10.764,
    'Square Yards': 9.0,
    'Acre': 43560.0,
    'Hectare': 107639.0,
  };

  void _convert() {
    if (_inputController.text.isEmpty) {
      setState(() {
        _result = null;
        _allConversions = null;
      });
      return;
    }

    final input = double.tryParse(_inputController.text);
    if (input == null) return;

    // Convert to square feet first
    final sqFt = input * _toSqFt[_fromUnit]!;

    // Then convert to target unit
    final output = sqFt / _toSqFt[_toUnit]!;

    // Calculate all conversions
    final allConv = <String, double>{};
    for (final unit in _units) {
      allConv[unit] = sqFt / _toSqFt[unit]!;
    }

    setState(() {
      _result = output;
      _allConversions = allConv;
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text('unit_converter'.tr(ref)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Card
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
                    TextField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      onChanged: (_) => _convert(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _fromUnit,
                      isExpanded: true,
                      isDense: true,
                      underline: Container(),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _fromUnit = value);
                          _convert();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Swap Button
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _swapUnits,
                  icon: const Icon(Icons.swap_vert, color: Color(0xFF2E7D32)),
                  iconSize: 32,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Output Card
            Card(
              elevation: 2,
              color: _result != null
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE8F5E9))
                  : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _result != null
                          ? (_result! < 1
                                ? _result!.toStringAsFixed(4)
                                : _result!.toStringAsFixed(2))
                          : '0',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _result != null
                            ? const Color(0xFF2E7D32)
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _toUnit,
                      isExpanded: true,
                      isDense: true,
                      underline: Container(),
                      style: TextStyle(
                        fontSize: 16,
                        color: _result != null
                            ? const Color(0xFF2E7D32)
                            : Theme.of(context).disabledColor,
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _toUnit = value);
                          _convert();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Convert Button
            if (_inputController.text.isNotEmpty)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _convert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'convert',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // All Conversions Grid
            if (_allConversions != null) ...[
              const SizedBox(height: 24),
              const Text(
                'All Conversions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _allConversions!.entries.map((entry) {
                      final value = entry.value;
                      final displayValue = value < 1
                          ? value.toStringAsFixed(4)
                          : value.toStringAsFixed(2);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              displayValue,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Info Note
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[900]!.withOpacity(0.3)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For regional units like Bigha, Katha, use Custom Unit feature in Results',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
