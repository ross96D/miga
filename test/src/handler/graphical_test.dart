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
    markTestSkipped("TODO");
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
}

class _MyBadMultipleSpans extends Diagnostic {
  @override
  String? get code => null; // The Rust test doesn't set a code.

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

  _MyBadMultipleSpans(this.src, this.highlight1, {this.highlight2, this.help});

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
  Iterable<Diagnostic>? get related => null;

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
  @override
  String get code => "baby::error";

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
