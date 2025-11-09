// ignore_for_file: prefer_double_quotes

import 'package:miga/src/handler/narratable.dart';
import 'package:miga/src/protocol.dart';
import 'package:miga/src/source_impl.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class MyBad extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight];

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;

  final LabeledSourceSpan highlight;

  MyBad(this.src, this.highlight);

  @override
  String display() {
    return "oops!";
  }
}

void main() {
  test("single line with wide char", () {
    final src = SourceCodeString("source\n  👼🏼text\n    here");
    final span = LabeledSourceSpan("this bit here", 9, 6);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   👼🏼text
    label at line 2, columns 3 to 6: this bit here
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("single line highlight", () {
    final src = SourceCodeString("source\n  text\n    here");
    final span = LabeledSourceSpan("this bit here", 9, 4);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label at line 2, columns 3 to 6: this bit here
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("single line highlight offset zero", () {
    final src = SourceCodeString("source\n  text\n    here");
    final span = LabeledSourceSpan("this bit here", 0, 0);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
    label at line 1, column 1: this bit here
snippet line 2:   text
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("single line highlight with empty span", () {
    final src = SourceCodeString("source\n  text\n    here");
    final span = LabeledSourceSpan("this bit here", 9, 0);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label at line 2, column 3: this bit here
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("single line highlight no label", () {
    final src = SourceCodeString("source\n  text\n    here");
    final span = LabeledSourceSpan(null, 9, 4);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label at line 2, columns 3 to 6
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("single line highlight at line start", () {
    final src = SourceCodeString("source\ntext\n  here");
    final span = LabeledSourceSpan("this bit here", 7, 4);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2: text
    label at line 2, columns 1 to 4: this bit here
snippet line 3:   here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("multiple same line highlights", () {
    final src = SourceCodeString("source\n  text text text text text\n    here");
    final highlight1 = LabeledSourceSpan("x", 9, 4);
    final highlight2 = LabeledSourceSpan("y", 14, 4);
    final highlight3 = LabeledSourceSpan("z", 24, 4);

    final buffer = StringBuffer();
    final diagnostic = _MultipleHighlightsBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2, highlight3],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text text text text text
    label at line 2, columns 3 to 6: x
    label at line 2, columns 8 to 11: y
    label at line 2, columns 18 to 21: z
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("multiline highlight adjacent", () {
    final src = SourceCodeString("source\n  text\n    here");
    final span = LabeledSourceSpan("these two lines", 9, 11);

    final buffer = StringBuffer();
    NarratableReportHandler(1).report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label starting at line 2, column 3: these two lines
snippet line 3:     here
    label ending at line 3, column 6: these two lines
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("multiline highlight flyby", () {
    final src = SourceCodeString("line1\nline2\nline3\nline4\nline5\n");
    final len = src.str.length;
    final highlight1 = LabeledSourceSpan("block 1", 0, len);
    final highlight2 = LabeledSourceSpan("block 2", 10, 9);

    final buffer = StringBuffer();
    final diagnostic = _MultipleHighlightsBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: line1
    label starting at line 1, column 1: block 1
snippet line 2: line2
    label starting at line 2, column 5: block 2
snippet line 3: line3
snippet line 4: line4
    label ending at line 4, column 1: block 2
snippet line 5: line5
    label ending at line 5, column 5: block 1
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("multiline highlight no label", () {
    final src = SourceCodeString("line1\nline2\nline3\nline4\nline5\n");
    final len = src.str.length;
    final highlight1 = LabeledSourceSpan("block 1", 0, len);
    final highlight2 = LabeledSourceSpan(null, 10, 9);

    final buffer = StringBuffer();
    final diagnostic = _NestedBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""wtf?!
it broke :(
    Diagnostic severity: error
    Caused by: something went wrong

Here's a more detailed explanation of everything that actually went wrong because it's actually important.

    Caused by: very much went wrong
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: line1
    label starting at line 1, column 1: block 1
snippet line 2: line2
    label starting at line 2, column 5
snippet line 3: line3
snippet line 4: line4
    label ending at line 4, column 1
snippet line 5: line5
    label ending at line 5, column 5: block 1
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("multiple multiline highlights adjacent", () {
    final src = SourceCodeString("source\n  text\n    here\nmore here");
    final highlight1 = LabeledSourceSpan("this bit here", 0, 10);
    final highlight2 = LabeledSourceSpan("also this bit", 20, 6);

    final buffer = StringBuffer();
    final diagnostic = _MultipleHighlightsBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
    label starting at line 1, column 1: this bit here
snippet line 2:   text
    label ending at line 2, column 3: this bit here
snippet line 3:     here
    label starting at line 3, column 7: also this bit
snippet line 4: more here
    label ending at line 4, column 3: also this bit
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
  );
  });

  test("multiple multiline highlights overlapping lines", () {
    final src = SourceCodeString("source\n  text\n    here");
    final highlight1 = LabeledSourceSpan("this bit here", 0, 8);
    final highlight2 = LabeledSourceSpan("also this bit", 9, 10);

    final buffer = StringBuffer();
    final diagnostic = _MultipleHighlightsBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    // This test is expected to fail currently, similar to Rust version
    expect("$buffer", isNotEmpty);
  }, skip: "This breaks because highlights aren't 'truly' overlapping");

  test("multiple multiline highlights overlapping offsets", () {
    final src = SourceCodeString("source\n  text\n    here");
    final highlight1 = LabeledSourceSpan("this bit here", 0, 8);
    final highlight2 = LabeledSourceSpan("also this bit", 10, 10);

    final buffer = StringBuffer();
    final diagnostic = _MultipleHighlightsBad(
      NamedSourceCode("bad_file.dart", src),
      [highlight1, highlight2],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    // This test is expected to fail currently, similar to Rust version
    expect("$buffer", isNotEmpty);
  }, skip: "This breaks because offsets are overlapping");

  test("url", () {
    final buffer = StringBuffer();
    final diagnostic = _UrlBad();
    NarratableReportHandler(1).report(diagnostic, buffer);
    expect("$buffer", contains("https://example.com"));
  });

  test("related", () {
    final src = SourceCodeString("source\n  text\n    here");
    final highlight = LabeledSourceSpan("this bit here", 9, 4);
    final relatedHighlight = LabeledSourceSpan("this bit here", 0, 6);

    final buffer = StringBuffer();
    final diagnostic = _RelatedBad(
      NamedSourceCode("bad_file.dart", src),
      highlight,
      [
        MyBad(NamedSourceCode("bad_file.dart", src), relatedHighlight),
      ],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label at line 2, columns 3 to 6: this bit here
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad

Error: oops!
    Diagnostic severity: error

Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
    label at line 1, columns 1 to 6: this bit here
snippet line 2:   text
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad
"""),
    );
  });

  test("related source code propagation", () {
    final src = SourceCodeString("source\n  text\n    here");
    final highlight = LabeledSourceSpan("this bit here", 9, 4);
    final relatedHighlight = LabeledSourceSpan("this bit here", 0, 6);

    final buffer = StringBuffer();
    final diagnostic = _RelatedPropagationBad(
      NamedSourceCode("bad_file.dart", src),
      highlight,
      [
        _InnerError(relatedHighlight),
      ],
    );
    NarratableReportHandler(1).report(diagnostic, buffer);

    expect(
      "$buffer",
      equals("""oops!
    Diagnostic severity: error
Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
snippet line 2:   text
    label at line 2, columns 3 to 6: this bit here
snippet line 3:     here
diagnostic help: try doing it better next time?
diagnostic code: oops.my.bad

Error: oops!
    Diagnostic severity: error

Begin snippet for bad_file.dart starting at line 1, column 1

snippet line 1: source
    label at line 1, columns 1 to 6: this bit here
snippet line 2:   text
diagnostic code: oops.my.bad
"""),
    );
  });
}


class _MultipleHighlightsBad extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => highlights;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final List<LabeledSourceSpan> highlights;

  _MultipleHighlightsBad(this.src, this.highlights);

  @override
  String display() {
    return "oops!";
  }
}

class _NestedBad extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => _Inner(_InnerInner());

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => highlights;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final List<LabeledSourceSpan> highlights;

  _NestedBad(this.src, this.highlights);

  @override
  String display() {
    return "wtf?!\nit broke :(";
  }
}

class _Inner extends Diagnostic {
  @override
  String get code => "";

  @override
  Diagnostic? get diagnosticSource => inner;

  @override
  String? get help => null;

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  final _InnerInner inner;

  _Inner(this.inner);

  @override
  String display() {
    return "something went wrong\n\nHere's a more detailed explanation of everything that actually went wrong because it's actually important.\n";
  }
}

class _InnerInner extends Diagnostic {
  @override
  String get code => "";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => null;

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  @override
  String display() {
    return "very much went wrong";
  }
}

class _UrlBad extends Diagnostic {
  @override
  String get code => "";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => "https://example.com";

  @override
  String display() {
    return "oops!";
  }
}

class _RelatedBad extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight];

  @override
  Iterable<Diagnostic>? get related => _related;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final LabeledSourceSpan highlight;
  final List<Diagnostic> _related;

  _RelatedBad(this.src, this.highlight, this._related);

  @override
  String display() {
    return "oops!";
  }
}

class _RelatedPropagationBad extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => "try doing it better next time?";

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight];

  @override
  Iterable<Diagnostic>? get related => _related;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final LabeledSourceSpan highlight;
  final List<Diagnostic> _related;

  _RelatedPropagationBad(this.src, this.highlight, this._related);

  @override
  String display() {
    return "oops!";
  }
}

class _InnerError extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => null;

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight];

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  final LabeledSourceSpan highlight;

  _InnerError(this.highlight);

  @override
  String display() {
    return "oops!";
  }
}
