// ignore_for_file: prefer_double_quotes

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:miga/src/protocol.dart';

MigaSpanContent _contextInfo(
  ByteData input,
  SourceSpan span,
  int contextLinesBefore,
  int contextLinesAfter,
) {
  final state = _State(
    offset: 0,
    lineCount: 0,
    startLine: 0,
    startColumn: 0,
    beforeLineStarts: Queue(),
    currentLineStart: 0,
    endLines: 0,
    posSpan: false,
    posSpanGotNewline: false,
  );

  final iter = Uint8List.sublistView(input).iterator;

  while (iter.moveNext()) {
    var char = iter.current;
    if (char == '\r'.codeUnitAt(0) || char == '\n'.codeUnitAt(0)) {
      state.lineCount += 1;
      if (char == '\r'.codeUnitAt(0)) {
        if (iter.moveNext()) {
          char = iter.current;
          if (char != '\n'.codeUnitAt(0)) {
            throw "TODO: handle legacy line break in macos that only contains /r";
          }
          state.offset += 1;
        }
      }

      if (state.offset < span.offset) {
        // We're before the start of the span.
        state.startColumn = 0;
        state.beforeLineStarts.add(state.currentLineStart);
        if (state.beforeLineStarts.length > contextLinesBefore) {
          state.startLine += 1;
          state.beforeLineStarts.removeFirst();
        }
      } else if (state.offset >= (span.offset + max(span.length - 1, 0))) {
        // We're after the end of the span, but haven't necessarily
        // started collecting end lines yet (we might still be
        // collecting context lines).
        if (state.posSpan) {
          state.startColumn = 0;
          if (state.posSpanGotNewline) {
            state.endLines += 1;
          } else {
            state.posSpanGotNewline = true;
          }
          if (state.endLines >= contextLinesAfter) {
            state.offset += 1;
            break;
          }
        }
      }
      state.currentLineStart = state.offset + 1;
    } else if (state.offset < span.offset) {
      state.startColumn += 1;
    }

    if (state.offset >= (span.offset + max(span.length - 1, 0))) {
      state.posSpan = true;
      if (state.endLines >= contextLinesAfter) {
        state.offset += 1;
        break;
      }
    }

    state.offset += 1;
  }

  if (state.offset >= (span.offset + max(span.length - 1, 0))) {
    final beforeLineStartsFirst = state.beforeLineStarts.firstOrNull;
    final startingOffset = beforeLineStartsFirst ?? (contextLinesBefore == 0 ? span.offset : 0);
    final length = state.offset - startingOffset;

    return MigaSpanContent(
      data: input.buffer.asByteData(startingOffset, length),
      span: SourceSpan.simple(startingOffset, length),
      line: state.startLine,
      column: contextLinesBefore == 0 ? state.startColumn : 0,
      lineCount: state.lineCount,
      language: null,
      name: null,
    );
  }
  // TODO 2: throw a proper error type;
  throw "Span is out of bounds";
}

class _State {
  Queue<int> beforeLineStarts;
  int currentLineStart;
  int endLines;
  int lineCount;
  int offset;
  bool posSpan;
  bool posSpanGotNewline;
  int startColumn;
  int startLine;
  _State({
    required this.beforeLineStarts,
    required this.currentLineStart,
    required this.endLines,
    required this.lineCount,
    required this.offset,
    required this.posSpan,
    required this.posSpanGotNewline,
    required this.startColumn,
    required this.startLine,
  });
}

class SourceCodeUint8List extends SourceCode {
  final Uint8List list;
  const SourceCodeUint8List(this.list);

  @override
  SpanContents readSpan(SourceSpan span, int contextLinesBefore, int contextLinesAfter) {
    return _contextInfo(list.buffer.asByteData(), span, contextLinesBefore, contextLinesAfter);
  }
}

/// This is needs to call utf8.encode wich makes it slower than [SourceCodeUint8List]
class SourceCodeString extends SourceCode {
  final String str;
  const SourceCodeString(this.str);

  @override
  SpanContents readSpan(SourceSpan span, int contextLinesBefore, int contextLinesAfter) {
    return _contextInfo(
      utf8.encode(str).buffer.asByteData(),
      span,
      contextLinesBefore,
      contextLinesAfter,
    );
  }
}

class NamedSourceCode<T extends SourceCode> extends SourceCode {
  T source;
  final String name;
  final String? language;

  NamedSourceCode(this.name, this.source, [this.language]);

  @override
  SpanContents readSpan(SourceSpan span, int contextLinesBefore, int contextLinesAfter) {
    final innerContent = source.readSpan(span, contextLinesBefore, contextLinesAfter);

    return MigaSpanContent(
      name: name,
      data: innerContent.data,
      span: innerContent.span,
      line: innerContent.line,
      column: innerContent.column,
      lineCount: innerContent.lineCount,
      language: language,
    );
  }
}
