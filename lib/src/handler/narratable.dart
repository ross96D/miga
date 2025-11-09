import "dart:convert";
import "dart:typed_data";

import "package:miga/src/diagnostic_chain.dart";
import "package:miga/src/protocol.dart";
import "package:miga/src/utils.dart";

class NarratableReportHandler extends ReportHandler {
  final int contextLines;
  final String? footer;
  final bool withCauses;

  NarratableReportHandler(this.contextLines, {this.footer, this.withCauses = true});

  @override
  void report(Diagnostic error, StringBuffer buffer) {
    renderHeader(error, buffer);
    if (withCauses) renderCauses(error, buffer);

    final src = error.sourceCode;
    renderSnippets(error, src, buffer);
    renderFooter(error, buffer);
    renderRelated(error, src, buffer);
  }

  void renderHeader(Diagnostic error, StringBuffer buffer) {
    buffer.writeln(error.display());
    buffer.write("    Diagnostic severity: ");
    buffer.writeln(switch (error.severity) {
      null => "error",
      Severity.error => "error",
      Severity.warning => "warning",
      Severity.advice => "advice",
    });
  }

  void renderFooter(Diagnostic error, StringBuffer buffer) {
    if (error.help != null) buffer.writeln("diagnostic help: ${error.help}");
    if (error.code != null) buffer.writeln("diagnostic code: ${error.code}");
    if (error.url != null) buffer.writeln("For more details, see:\n${error.url}");
  }

  void renderCauses(Diagnostic error, StringBuffer buffer) {
    if (error.diagnosticSource == null) return;
    for (final diag in DiagnosticChain(error.diagnosticSource).iter()) {
      buffer.write("    Caused by: ");
      buffer.writeln(diag.display());
    }
  }

  void renderRelated(Diagnostic error, SourceCode? parentSource, StringBuffer buffer) {
    if (error.related == null) return;

    buffer.writeln();
    for (final related in error.related!) {
      switch (related.severity) {
        case null || Severity.error:
          buffer.write("Error: ");
        case Severity.warning:
          buffer.write("Warning: ");
        case Severity.advice:
          buffer.write("Advice: ");
      }
      renderHeader(related, buffer);
      buffer.writeln();
      final src = related.sourceCode ?? parentSource;
      renderSnippets(related, src, buffer);
      renderFooter(related, buffer);
      renderRelated(related, src, buffer);
    }
  }

  void renderSnippets(Diagnostic error, SourceCode? source, StringBuffer buffer) {
    if (source == null) return;
    if (error.labels == null) return;

    final labels = error.labels!.toList();
    labels.sort((a, b) => a.offset - b.offset);
    final contents = labels.map((l) => source.readSpan(l, contextLines, contextLines)).toList();

    final contexts = <(LabeledSourceSpan, SpanContents)>[];
    for (final (right, rightConts) in zip2((labels, contents))) {
      if (contexts.isEmpty) {
        contexts.add((right, rightConts));
        continue;
      }
      final (left, leftConts) = contexts.last;
      final leftEnd = left.offset + left.length;
      final rightEnd = right.offset + right.length;
      if (leftConts.line + leftConts.lineCount < rightConts.line) {
        contexts.add((right, rightConts));
        continue;
      }

      final newSpanLenght = switch (rightEnd >= leftEnd) {
        true => rightEnd - left.offset,
        false => left.length,
      };
      final newSpan = LabeledSourceSpan(left.label, left.offset, newSpanLenght);

      try {
        source.readSpan(newSpan, contextLines, contextLines);
        contexts.removeLast();
        contexts.add((newSpan, leftConts));
      } catch (_) {
        // TODO catch expecific OutOfBounds error only
        contexts.add((right, rightConts));
      }
    }

    for (final (ctx, _) in contexts) {
      renderContext(source, ctx, labels, buffer);
    }
  }

  void renderContext(
    SourceCode source,
    LabeledSourceSpan context,
    List<LabeledSourceSpan> labels,
    StringBuffer buffer,
  ) {
    final (contents, lines) = getLines(source, context.span);
    buffer.write("Begin snippet");
    if (contents.name != null) {
      buffer.write(" for ${contents.name}");
    }
    buffer.writeln(" starting at line ${contents.line + 1}, column ${contents.column + 1}");
    buffer.writeln();

    for (final line in lines) {
      buffer.writeln("snippet line ${line.lineNumber}: ${line.text}");
      final relevants = labels
          .map((label) {
            final attach = line.spanAttach(label);
            if (attach == null) return null;
            return (attach, label);
          })
          .where((e) => e != null)
          .cast<(_SpanAttach, LabeledSourceSpan)>();

      for (final (attach, label) in relevants) {
        switch (attach) {
          case _SpanAttachContained():
            if (attach.colStart == attach.colEnd) {
              buffer.write("    label at line ${line.lineNumber}, column ${attach.colStart}");
            } else {
              buffer.write(
                "    label at line ${line.lineNumber}, columns ${attach.colStart} to ${attach.colEnd}",
              );
            }
          case _SpanAttachStarts():
            buffer.write(
              "    label starting at line ${line.lineNumber}, column ${attach.colStart}",
            );
          case _SpanAttachEnds():
            buffer.write("    label ending at line ${line.lineNumber}, column ${attach.colEnd}");
        }
        if (label.label != null) {
          buffer.write(": ${label.label}");
        }
        buffer.writeln();
      }
    }
  }

  (SpanContents, List<_Line>) getLines(SourceCode source, SourceSpan contextSpan) {
    final contextData = source.readSpan(contextSpan, contextLines, contextLines);
    final context = utf8.decode(Uint8List.sublistView(contextData.data));
    final contextLength = context.runes.length;

    var line = contextData.line;
    var column = contextData.column;
    var offset = contextData.span.offset;
    var lineOffset = offset;
    final lineStr = StringBuffer();
    final lines = <_Line>[];

    final iter = context.runes.iterator;
    var count = 0;
    while (iter.moveNext()) {
      count += 1;
      final char = iter.current;
      final width = char.utf8ByteLength();

      offset += width;
      var atEOF = false;

      if (char == "\r".codeUnitAt(0)) {
        iter.moveNext();
        count += 1;
        if (iter.current != "\n".codeUnitAt(0)) throw "unsuported \\r without \\n after";

        offset += 1;
        line += 1;
        column = 0;
        atEOF = count == contextLength;
      } else if (char == "\n".codeUnitAt(0)) {
        atEOF = count == contextLength;
        line += 1;
        column = 0;
      } else {
        lineStr.writeCharCode(char);
        column += 1;
      }

      if (count == contextLength && !atEOF) {
        line += 1;
      }

      if (column == 0 || count == contextLength) {
        lines.add(
          _Line(lineNumber: line, offset: lineOffset, text: lineStr.toString(), atEOF: atEOF),
        );
        lineStr.clear();
        lineOffset = offset;
      }
    }
    assert(count == contextLength);
    return (contextData, lines);
  }
}

class _Line {
  int lineNumber;
  int offset;
  String text;
  bool atEOF;

  _Line({required this.lineNumber, required this.offset, required this.text, required this.atEOF});

  _SpanAttach? spanAttach(SourceSpan span) {
    final spanEnd = span.offset + span.length;
    final lineEnd = offset + text.length;

    final startAfter = span.offset >= offset;
    final endBefore = atEOF || spanEnd <= lineEnd;

    if (startAfter && endBefore) {
      final colStart = _safeGetColumn(text, span.offset - offset, true);
      final colEnd = switch (span.isEmpty) {
        true => colStart,
        false => _safeGetColumn(text, spanEnd - offset, false),
      };
      return _SpanAttachContained(colStart, colEnd);
    }

    if (startAfter && span.offset <= lineEnd) {
      final colStart = _safeGetColumn(text, span.offset - offset, true);
      return _SpanAttachStarts(colStart);
    }
    if (endBefore && spanEnd >= offset) {
      final colEnd = _safeGetColumn(text, spanEnd - offset, false);
      return _SpanAttachEnds(colEnd);
    }

    return null;
  }
}

/// Returns column at offset, and nearest boundary if offset is in the middle of
/// the character
int _safeGetColumn(String text, int offset, bool start) {
  var column = 0;
  var idx = -1;
  final runeIter = text.runes.iterator;

  while (runeIter.moveNext()) {
    final rune = runeIter.current;
    final charLen = rune.utf8ByteLength();
    idx += charLen;

    if (idx >= offset) {
      break;
    }

    column += charLen;
  }

  if (start) {
    column += 1;
  }
  return column;
}

sealed class _SpanAttach {}

class _SpanAttachContained extends _SpanAttach {
  final int colStart;
  final int colEnd;

  _SpanAttachContained(this.colStart, this.colEnd);
}

class _SpanAttachStarts extends _SpanAttach {
  final int colStart;

  _SpanAttachStarts(this.colStart);
}

class _SpanAttachEnds extends _SpanAttach {
  final int colEnd;

  _SpanAttachEnds(this.colEnd);
}
