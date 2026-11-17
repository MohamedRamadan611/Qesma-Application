import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/name_key.dart';

void main() {
  test('trims, collapses every whitespace run and lower-cases', () {
    expect(memberNameKey('  Ahmed \t\n ALI  '), 'ahmed ali');
    expect(memberNameKey('Ahmed Ali'), 'ahmed ali', reason: 'NBSP is whitespace');
    expect(memberNameKey('ÉLODIE'), 'élodie', reason: 'Unicode lower case, not ASCII only');
  });

  test('Arabic is only trimmed and collapsed: letters and marks are kept as typed', () {
    expect(memberNameKey('  محمد   علي '), 'محمد علي');
    expect(memberNameKey('أحمد'), isNot(memberNameKey('احمد')));
    expect(memberNameKey('أَحمد'), isNot(memberNameKey('أحمد')));
  });
}
