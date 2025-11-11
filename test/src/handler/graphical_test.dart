import "package:miga/src/diagnostic_impl.dart";
import "package:miga/src/handler/graphical.dart";
import "package:miga/src/protocol.dart";
import "package:miga/src/source_impl.dart";
import "package:test/test.dart";

import "narratable_test.dart";

String report(
  Diagnostic diagnostic, [
  GraphicalReportHandler Function(GraphicalReportHandler)? handler,
]) {
  final buffer = StringBuffer();
  var reporter = GraphicalReportHandler.newThemed(MigaGraphicalTheme.unicodeNoColor());
  reporter = handler?.call(reporter) ?? reporter;
  reporter.report(diagnostic, buffer);
  return buffer.toString();
}

void main() {
  test("word wrap options", () {
    {
      final actual = report(MigaDiagnostic.string("abcdefghijklmnopqrstuvwxyz"));
      final expected = "  × abcdefghijklmnopqrstuvwxyz\n";
      expect(actual, equals(expected));
    }
    {
      final actual = report(
        MigaDiagnostic.string("abcdefghijklmnopqrstuvwxyz"),
        (v) => v.copyWith(footer: null, linkDisplayText: null, termWidth: 10),
      );
      final expected = """  × abcd
  │ efgh
  │ ijkl
  │ mnop
  │ qrst
  │ uvwx
  │ yz
""";
      expect(actual, equals(expected));
    }

    {
      final actual = report(
        MigaDiagnostic.string("abcdefghijklmnopqrstuvwxyz"),
        (v) => v.copyWith(footer: null, linkDisplayText: null, termWidth: 10, breakWords: false),
      );
      final expected = "  × abcdefghijklmnopqrstuvwxyz\n";
      expect(actual, equals(expected));
    }
  });

  test("wrapping nested errors", () {
    final diagnostic = _MamaError(_BabyError());

    // Use the report function with the specified configuration
    final actual = report(
      diagnostic,
      (v) => v.copyWith(footer: null, linkDisplayText: null, termWidth: 50),
    );

    expect(
      actual,
      equals("""mama::error

  × This is the parent error, the error withhhhh
  │ the children, kiddos, pups, as it were, and
  │ so on...
  ╰─▶ baby::error

        × Wah wah: I may be small, but I'll
        │ cause a proper bout of trouble — justt
        │ try wrapping this mess of a line,
        │ buddo!
        help: it cannot be helped... woulddddddd
              you really want to get rid of an
              error that's so cute?

  help: try doing it better next time? I mean,
        you could have also done better thisssss
        time, but no?
"""),
    );
  });

  test("wrapping related errors", () {
    final diagnostic = _MamaErrorWithRelated(
      _BrotherError([
        _BabyError(false),
        _BabyWarning(),
        _BabyAdvice(),
      ]),
    );

    final actual = report(
      diagnostic,
      (v) => v.copyWith(footer: null, linkDisplayText: null, termWidth: 50),
    );

    expect(
      actual,
      equals("""mama::error

  × This is the parent error, the error withhhhh
  │ the children, kiddos, pups, as it were, and
  │ so on...
  ╰─▶ brother::error

        × Welcome to the brother-error
        │ brotherhood — where all of the wee
        │ baby errors join into a formidable
        │ force

      Error:
        × Wah wah: I may be small, but I'll
        │ cause a proper bout of trouble — justt
        │ try wrapping this mess of a line,
        │ buddo!
        help: it cannot be helped... woulddddddd
              you really want to get rid of an
              error that's so cute?

      Warning:
        ⚠ Wah wah: I may be small, but I'll
        │ cause a proper bout of trouble — justt
        │ try wrapping this mess of a line,
        │ buddo!

      Advice:
        ☞ Wah wah: I may be small, but I'll
        │ cause a proper bout of trouble — justt
        │ try wrapping this mess of a line,
        │ buddo!

  help: try doing it better next time? I mean,
        you could have also done better thisssss
        time, but no?
"""),
    );
  });

  test("empty source", () {
    final src = SourceCodeString("");
    final span = LabeledSourceSpan("this bit here", 0, 0);

    final diagnostic = MyBad(NamedSourceCode("bad_file.dart", src), span);

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.dart:1:1]
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("multiple spans multiline", () {
    final src = SourceCodeString("if true {\n    a\n} else {\n    b\n}");
    final big = LabeledSourceSpan("big", 0, 32);
    final small = LabeledSourceSpan("small", 14, 1);

    final diagnostic = _MyBadMultipleSpans(NamedSourceCode("issue", src), big, highlight2: small);

    // Use GraphicalReportHandler with a fixed width? The Rust test doesn't set width, so we use default.
    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[issue:1:1]
 1 │ ╭─▶ if true {
 2 │ │       a
   · │       ┬
   · │       ╰── small
 3 │ │   } else {
 4 │ │       b
 5 │ ├─▶ }
   · ╰──── big
   ╰────
"""),
    );
  });

  test("single line highlight span full line", () {
    final src = SourceCodeString("source\ntext");
    final big = LabeledSourceSpan("This bit here", 7, 4);

    final diagnostic = _MyBadMultipleSpans(NamedSourceCode("issue", src), big);

    // Use GraphicalReportHandler with a fixed width? The Rust test doesn't set width, so we use default.
    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[issue:2:1]
 1 │ source
 2 │ text
   · ──┬─
   ·   ╰── This bit here
   ╰────
"""),
    );
  });

  test("single line with wide char", () {
    final src = SourceCodeString("source\n  👼🏼text\n    here");

    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 13, 8),
      help: "try doing it better next time?",
    );

    // Use GraphicalReportHandler with a fixed width? The Rust test doesn't set width, so we use default.
    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[bad_file.rs:2:7]
 1 │ source
 2 │   👼🏼text
   ·     ───┬──
   ·        ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line with two tabs", () {
    final src = SourceCodeString("source\n\t\ttext\n    here");

    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 9, 4),
      help: "try doing it better next time?",
    );

    // Use GraphicalReportHandler with a fixed width? The Rust test doesn't set width, so we use default.
    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │         text
   ·         ──┬─
   ·           ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line with tab in middle", () {
    final src = SourceCodeString("source\ntext =\ttext\n    here");

    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 14, 4),
      help: "try doing it better next time?",
    );

    // Use GraphicalReportHandler with a fixed width? The Rust test doesn't set width, so we use default.
    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[bad_file.rs:2:8]
 1 │ source
 2 │ text =  text
   ·         ──┬─
   ·           ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 9, 4),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ──┬─
   ·     ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("external source", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadExternalSource(
      LabeledSourceSpan("this bit here", 9, 4),
      help: "try doing it better next time?",
    );

    // Attach source code externally like in Rust test
    final actual = report(
      diagnostic.withSourceCode(NamedSourceCode("bad_file.rs", src)),
    );

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ──┬─
   ·     ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight offset zero", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 0, 0),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:1:1]
 1 │ source
   · ▲
   · ╰── this bit here
 2 │   text
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight offset end of line", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 6, 0),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:1:7]
 1 │ source
   ·       ▲
   ·       ╰── this bit here
 2 │   text
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight include end of line", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 9, 5),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ──┬──
   ·     ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight include end of line crlf", () {
    final src = SourceCodeString("source\r\n  text\r\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 10, 6),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ──┬──
   ·     ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight with empty span", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 9, 0),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ▲
   ·   ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight no label", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan(null, 9, 4),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ────
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("single line highlight at line start", () {
    final src = SourceCodeString("source\ntext\n  here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 7, 4),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:1]
 1 │ source
 2 │ text
   · ──┬─
   ·   ╰── this bit here
 3 │   here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("multiline label", () {
    final src = SourceCodeString("source\ntext\n  here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here\nand\nthis\ntoo", 7, 4),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:1]
 1 │ source
 2 │ text
   · ──┬─
   ·   ╰─┤ this bit here
   ·     │ and
   ·     │ this
   ·     │ too
 3 │   here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("multiple same line highlights", () {
    final src = SourceCodeString("source\n  text text text text text\n    here");
    final diagnostic = _MyBadMultipleLabels(
      NamedSourceCode("bad_file.rs", src),
      [
        LabeledSourceSpan("x", 9, 4),
        LabeledSourceSpan("y", 14, 4),
        LabeledSourceSpan("z", 24, 4),
      ],
      help: "try doing it better next time?",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text text text text text
   ·   ──┬─ ──┬─      ──┬─
   ·     │    │         ╰── z
   ·     │    ╰── y
   ·     ╰── x
 3 │     here
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("multiline highlight adjacent", () {
    final src = SourceCodeString("source\n  text\n    here");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("these two lines", 9, 11),
      help: "try doing it better next time?",
      code: "oops.my.bad",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │     source
 2 │ ╭─▶   text
 3 │ ├─▶     here
   · ╰──── these two lines
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("multiple multiline highlights adjacent", () {
    final src = SourceCodeString("source\n  text\n    here\nmore here");
    final diagnostic = _MyBadMultipleLabels(
      NamedSourceCode("bad_file.rs", src),
      [
        LabeledSourceSpan("this bit here", 0, 10),
        LabeledSourceSpan("also this bit", 20, 6),
      ],
      help: "try doing it better next time?",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:1:1]
 1 │ ╭─▶ source
 2 │ ├─▶   text
   · ╰──── this bit here
 3 │ ╭─▶     here
 4 │ ├─▶ more here
   · ╰──── also this bit
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("url links", () {
    final diagnostic = _MyBadWithUrl();

    final actual = report(diagnostic);

    expect(actual, contains("https://example.com"));
    expect(actual, contains("(link)"));
    expect(actual, contains("oops.my.bad"));
  });

  test("related", () {
    // return markTestSkipped("TODO");
    final src = SourceCodeString("source\n  text\n    here");
    final related = [
      _MyBadMultipleSpans(
        NamedSourceCode("bad_file.rs", src),
        LabeledSourceSpan("this bit here", 0, 6),
        help: "try doing it better next time?",
        code: "oops.my.bad",
      ),
    ];

    final diagnostic = _MyBadWithRelated(
      NamedSourceCode("bad_file.rs", src),
      LabeledSourceSpan("this bit here", 9, 4),
      related,
      help: "try doing it better next time?",
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""oops.my.bad

  × oops!
   ╭─[bad_file.rs:2:3]
 1 │ source
 2 │   text
   ·   ──┬─
   ·     ╰── this bit here
 3 │     here
   ╰────
  help: try doing it better next time?

Error: oops.my.bad

  × oops!
   ╭─[bad_file.rs:1:1]
 1 │ source
   · ───┬──
   ·    ╰── this bit here
 2 │   text
   ╰────
  help: try doing it better next time?
"""),
    );
  });

  test("zero length eol span", () {
    final src = SourceCodeString("this is the first line\nthis is the second line");
    final diagnostic = _MyBadMultipleSpans(
      NamedSourceCode("issue", src),
      LabeledSourceSpan("This bit here", 23, 0),
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[issue:2:1]
 1 │ this is the first line
 2 │ this is the second line
   · ▲
   · ╰── This bit here
   ╰────
"""),
    );
  });

  test("primary label", () {
    final src = SourceCodeString("this is the first line\nthis is the second line");
    final diagnostic = _MyBadWithPrimary(
      NamedSourceCode("issue", src),
      LabeledSourceSpan(null, 2, 4),
      LabeledSourceSpan("nope", 24, 4, true),
    );

    final actual = report(diagnostic);

    expect(
      actual,
      equals("""
  × oops!
   ╭─[issue:2:2]
 1 │ this is the first line
   ·   ────
 2 │ this is the second line
   ·  ──┬─
   ·    ╰── nope
   ╰────
"""),
    );
  });
}

class _MyBadMultipleSpans extends Diagnostic {
  @override
  String? code; // The Rust test doesn't set a code.

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? help;

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight1, ?highlight2];

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final LabeledSourceSpan highlight1;
  final LabeledSourceSpan? highlight2;

  _MyBadMultipleSpans(this.src, this.highlight1, {this.highlight2, this.help, this.code});

  @override
  String display() {
    return "oops!";
  }

  @override
  Severity get severity => Severity.error;
}

class _MamaError extends Diagnostic {
  @override
  String get code => "mama::error";

  @override
  Diagnostic? get diagnosticSource => baby;

  @override
  String? get help =>
      "try doing it better next time? I mean, you could have also done better thisssss time, but no?";

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? related;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  final _BabyError baby;

  _MamaError(this.baby);

  @override
  String display() {
    return "This is the parent error, the error withhhhh the children, kiddos, pups, as it were, and so on...";
  }
}

class _BabyError extends Diagnostic {
  _BabyError([this.withCode = true]);
  bool withCode;

  @override
  String? get code => withCode ? "baby::error" : null;

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help =>
      "it cannot be helped... woulddddddd you really want to get rid of an error that's so cute?";

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
    return "Wah wah: I may be small, but I'll cause a proper bout of trouble — justt try wrapping this mess of a line, buddo!";
  }
}


class _MyBadExternalSource extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? help;

  @override
  Iterable<LabeledSourceSpan>? get labels => [highlight];

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? sourceCode;

  @override
  String? get url => null;

  final LabeledSourceSpan highlight;

  _MyBadExternalSource(this.highlight, {this.help});

  @override
  String display() {
    return "oops!";
  }

  @override
  Severity get severity => Severity.error;

  _MyBadExternalSource withSourceCode(NamedSourceCode source) {
    final newInstance = _MyBadExternalSource(highlight, help: help);
    newInstance.sourceCode = source;
    return newInstance;
  }
}

class _MyBadMultipleLabels extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? help;

  @override
  Iterable<LabeledSourceSpan>? get labels => _labels;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final List<LabeledSourceSpan> _labels;

  _MyBadMultipleLabels(this.src, this._labels, {this.help});

  @override
  String display() {
    return "oops!";
  }

  @override
  Severity get severity => Severity.error;
}

class _MyBadWithUrl extends Diagnostic {
  @override
  String get code => "oops.my.bad";

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

  @override
  Severity get severity => Severity.error;
}

class _MyBadWithRelated extends Diagnostic {
  @override
  String get code => "oops.my.bad";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? help;

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

  _MyBadWithRelated(this.src, this.highlight, this._related, {this.help});

  @override
  String display() {
    return "oops!";
  }

  @override
  Severity get severity => Severity.error;
}

class _MyBadWithPrimary extends Diagnostic {
  @override
  String? get code => null;

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => null;

  @override
  Iterable<LabeledSourceSpan>? get labels => [firstLabel, secondLabel];

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => src;

  @override
  String? get url => null;

  final NamedSourceCode<SourceCodeString> src;
  final LabeledSourceSpan firstLabel;
  final LabeledSourceSpan secondLabel;

  _MyBadWithPrimary(this.src, this.firstLabel, this.secondLabel);

  @override
  String display() {
    return "oops!";
  }

  @override
  Severity get severity => Severity.error;
}



class _MamaErrorWithRelated extends Diagnostic {
  @override
  String get code => "mama::error";

  @override
  Diagnostic? get diagnosticSource => baby;

  @override
  String? get help =>
      "try doing it better next time? I mean, you could have also done better thisssss time, but no?";

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  final _BrotherError baby;

  _MamaErrorWithRelated(this.baby);

  @override
  String display() {
    return "This is the parent error, the error withhhhh the children, kiddos, pups, as it were, and so on...";
  }

  @override
  Severity get severity => Severity.error;
}

class _BrotherError extends Diagnostic {
  @override
  String get code => "brother::error";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String? get help => null;

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => brethren;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;

  final List<Diagnostic> brethren;

  _BrotherError(this.brethren);

  @override
  String display() {
    return "Welcome to the brother-error brotherhood — where all of the wee baby errors join into a formidable force";
  }

  @override
  Severity get severity => Severity.error;
}

class _BabyWarning extends Diagnostic {
  @override
  String? get code => null;

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
    return "Wah wah: I may be small, but I'll cause a proper bout of trouble — justt try wrapping this mess of a line, buddo!";
  }

  @override
  Severity get severity => Severity.warning;
}

class _BabyAdvice extends Diagnostic {
  @override
  String? get code => null;

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
    return "Wah wah: I may be small, but I'll cause a proper bout of trouble — justt try wrapping this mess of a line, buddo!";
  }

  @override
  Severity get severity => Severity.advice;
}
