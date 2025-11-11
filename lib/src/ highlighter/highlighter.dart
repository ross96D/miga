import "package:miga/src/protocol.dart";

abstract class Highlighter {
  HighlighterState startHighlighterState(SpanContents source);
}

abstract class HighlighterState {
  String highlightLine(String line);
}

class BlankHighlighter implements Highlighter {
  @override
  HighlighterState startHighlighterState(SpanContents source) {
    return BlankHighlighterState();
  }
}

class BlankHighlighterState implements HighlighterState {
  @override
  String highlightLine(String line) {
    return line;
  }
}
