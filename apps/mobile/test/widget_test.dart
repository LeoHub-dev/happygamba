import 'package:flutter_test/flutter_test.dart';
import 'package:happygamba/core/theme.dart';

void main() {
  test('AppTheme has dark colors', () {
    expect(AppTheme.bgDark, isNotNull);
    expect(AppTheme.accentGreen, isNotNull);
  });
}
