// ignore_for_file: prefer_double_quotes

import 'dart:typed_data';

import "package:miga/src/handler/graphical.dart";

ReportHandler defaultReportHandler = GraphicalReportHandler.newThemed(MigaGraphicalTheme.unicode());

/// Adds rich metadata to your errors that can be used to
/// print really nice and human-friendly error messages.
abstract class Diagnostic implements Exception {
  /// Unique diagnostic code that can be used to look up more information
  /// about this [Diagnostic]. Ideally also globally unique.
  ///
  /// Requires a human readable implementation of toString.
  Object? get code;

  /// Diagnostic severity. This may be used by the report handler
  /// to change the display format of this diagnostic.
  ///
  /// Defaults to error.
  Severity? get severity => Severity.error;

  /// Additional help text related to this [Diagnostic]. Do you have any
  /// advice for the poor soul who's just run into this issue?
  String? get help;

  /// URL to visit for a more detailed explanation/help about this
  /// [Diagnostic].
  String? get url;

  /// Source code to apply this [Diagnostic]'s [Diagnostic.labels] to.
  SourceCode? get sourceCode;

  /// Labels to apply to this [Diagnostic]'s [Diagnostic.sourceCode]
  Iterable<LabeledSourceSpan>? get labels;

  /// Additional related [Diagnostic]'s.
  Iterable<Diagnostic>? get related;

  /// The cause of the error.
  Diagnostic? get diagnosticSource;

  String display();

  @override
  String toString([ReportHandler? handler]) {
    final buff = StringBuffer();
    (handler ?? defaultReportHandler).report(this, buff);
    return buff.toString();
  }
}

enum Severity { advice, warning, error }

/// Represents readable source code of some sort.
abstract class SourceCode {
  const SourceCode();

  SpanContents readSpan(SourceSpan span, int contextLinesBefore, int contextLinesAfter);
}

/// Span within a SourceCode
final class SourceSpan {
  /// The start of the span.
  final SourceOffset _sourceOffset;

  /// Total length of the [SourceSpan], in bytes.
  final int length;

  const SourceSpan(this._sourceOffset, this.length);
  factory SourceSpan.simple(int offset, int length) {
    return SourceSpan(SourceOffset(offset), length);
  }

  /// The absolute offset, in bytes, from the beginning of a [SourceCode].
  int get offset => _sourceOffset.offset;

  /// Whether this [SourceSpan] has a length of zero. It may still be useful
  /// to point to a specific point.
  bool get isEmpty => length == 0;

  @override
  bool operator ==(Object other) {
    return other is SourceSpan && other.length == length && other.offset == offset;
  }

  @override
  int get hashCode => Object.hashAll([length, offset]);
}

final class LabeledSourceSpan implements SourceSpan {
  /// Optional label string for this [LabeledSourceSpan].
  String? label;

  /// The inner [SourceSpan].
  final SourceSpan span;

  /// True if this [LabeledSourceSpan] is a primary span.
  final bool primary;

  /// True if this [LabeledSourceSpan] is empty.
  @override
  bool get isEmpty => span.isEmpty;

  /// Returns the number of bytes this [LabeledSourceSpan] spans.
  @override
  int get offset => span.offset;

  /// Total length of the [SourceSpan], in bytes.
  @override
  int get length => span.length;

  LabeledSourceSpan._({required this.label, required this.span, required this.primary});

  factory LabeledSourceSpan(String? label, int byteOffset, int length, [bool primary = false]) {
    return LabeledSourceSpan._(
      label: label,
      span: SourceSpan.simple(byteOffset, length),
      primary: primary,
    );
  }

  factory LabeledSourceSpan.withSpan(String? label, SourceSpan span, [bool primary = false]) {
    return LabeledSourceSpan._(label: label, span: span, primary: primary);
  }

  @override
  SourceOffset get _sourceOffset => throw UnimplementedError();
}

/// Represents the byte offset from the beginning of a [SourceCode]
final class SourceOffset {
  final int _byteOffset;
  const SourceOffset(this._byteOffset);

  int get offset => _byteOffset;
}

abstract class SpanContents {
  /// Reference to the data inside the associated span, in bytes.
  ByteData get data;

  /// [SourceSpan] representing the span covered by this [SpanContents].
  SourceSpan get span;

  /// An optional (file?) name for the container of this [SpanContents].
  String? get name;

  /// The 0-indexed line in the associated [SourceCode] where the data
  /// begins.
  int get line;

  /// The 0-indexed column in the associated [SourceCode] where the data
  /// begins, relative to `line`.
  int get column;

  /// Total number of lines covered by this [SpanContents].
  int get lineCount;

  /// Optional method. The language name for this source code, if any.
  /// This is used to drive syntax highlighting.
  ///
  /// Examples: Rust, TOML, C
  ///
  String? get language => null;
}

class MigaSpanContent implements SpanContents {
  @override
  final ByteData data;

  @override
  final SourceSpan span;

  @override
  final int line;

  @override
  final int column;

  @override
  final int lineCount;

  @override
  final String? name;

  @override
  final String? language;

  MigaSpanContent({
    required this.data,
    required this.span,
    required this.line,
    required this.column,
    required this.lineCount,
    required this.name,
    required this.language,
  });
}

/// Error Report Handler.
///
/// Define the report format for a Diagnostic
abstract class ReportHandler {
  void report(Diagnostic diagnostic, StringBuffer buffer);
}
