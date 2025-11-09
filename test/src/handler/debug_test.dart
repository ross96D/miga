import "package:miga/src/handler/debug.dart";
import "package:miga/src/protocol.dart";
import "package:miga/src/source_impl.dart";
import "package:test/scaffolding.dart";

class MyBad extends Diagnostic {
  @override
  String get code => "test.MyBad";

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
    return "oops";
  }
}

void main() {
  test("single line with wide char", () {
    return Skip();

    final src = SourceCodeString("source\n  👼🏼text\n    here");
    final span = LabeledSourceSpan("this bit here", 9, 6);

    final buffer = StringBuffer();
    DebugReportHandler().report(MyBad(NamedSourceCode("bad_file.dart", src), span), buffer);

    print("$buffer");
  });
}
