
// ignore_for_file: prefer_double_quotes

import "package:miga/src/protocol.dart";

class DiagnosticChain {
  Diagnostic? _state;

  DiagnosticChain(this._state);

  Iterable<Diagnostic> iter() sync* {
    if (_state == null) return;

    while (_state != null) {
      yield _state!;
      _state = _state?.diagnosticSource;
    }
  }
}
