// ignore_for_file: prefer_double_quotes

import "package:miga/src/protocol.dart";
import "package:miga/src/source_impl.dart";

class MigaDiagnostic extends Diagnostic {
  final String message;

  @override
  final String? code;

  @override
  final Severity? severity;

  @override
  final String? help;

  @override
  final String? url;

  @override
  final SourceCode? sourceCode;

  @override
  final Iterable<LabeledSourceSpan>? labels;

  @override
  final Iterable<Diagnostic>? related;

  @override
  final Diagnostic? diagnosticSource;

  MigaDiagnostic({
    required this.message,
    required this.code,
    required this.severity,
    required this.help,
    required this.url,
    required this.sourceCode,
    required this.labels,
    required this.related,
    required this.diagnosticSource,
  });

  MigaDiagnostic.string(this.message, {
    this.code,
    this.severity,
    this.help,
    this.url,
    this.sourceCode,
    this.labels,
    this.related,
    this.diagnosticSource,
  });

  factory MigaDiagnostic.formatExcpetion(String message, FormatException excpetion) {
    return MigaDiagnostic.string(
      message,
      sourceCode: SourceCodeString(excpetion.source),
      labels: [LabeledSourceSpan(excpetion.message, excpetion.offset ?? 0, 1)],
    );
  }

  @override
  String display() {
    return message;
  }
}
