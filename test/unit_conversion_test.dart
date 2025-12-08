import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Conversion Logic', () {
    test('Calculate custom unit from Square Feet', () {
      // Scenario: User has 1000 Sq Ft.
      // Custom Unit: "Bigha"
      // 1 Bigha = 100 Sq Ft (Hypothetical for easy math)
      // Expected Result: 10 Bigha
      
      const totalAreaSqFt = 1000.0;
      const customUnitValue = 100.0; // 1 Custom Unit = 100 Sq Ft
      
      // Logic: Total Area / Unit Value
      final result = totalAreaSqFt / customUnitValue;
      
      expect(result, 10.0);
    });

    test('Calculate custom unit from Square Meter', () {
      // Scenario: User has 1000 Sq Ft.
      // Custom Unit: "LocalUnit"
      // 1 LocalUnit = 10 Sq Meter
      
      const totalAreaSqFt = 1000.0;
      const sqFtToSqM = 0.092903;
      const totalAreaSqM = totalAreaSqFt * sqFtToSqM;
      
      const customUnitValue = 10.0; // 1 Custom Unit = 10 Sq M
      
      final result = totalAreaSqM / customUnitValue;
      
      expect(result, closeTo(9.2903, 0.0001));
    });
  });
}
