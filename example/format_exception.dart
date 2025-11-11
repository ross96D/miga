import "dart:convert";

import "package:miga/src/diagnostic_impl.dart";

void main() {
  final str = '{"key": "value", 12: 123}';
  try {
    json.decode(str);
  } on FormatException catch (e, st) {
    final diagnostic = MigaDiagnostic.formatExcpetion("malformed json provided", e);
    print(diagnostic);
    print(st);
  }
}
