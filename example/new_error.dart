import "package:miga/miga.dart";

class NewError extends Diagnostic {
  @override
  String get code => "E01";

  @override
  Diagnostic? get diagnosticSource => null;

  @override
  String display() {
    return "this is a new error example";
  }

  @override
  String? get help => "say something to help the user understand the error";

  @override
  Iterable<LabeledSourceSpan>? get labels => null;

  @override
  Iterable<Diagnostic>? get related => null;

  @override
  SourceCode? get sourceCode => null;

  @override
  String? get url => null;
}

void main() {
  defaultReportHandler = GraphicalReportHandler.newThemed(MigaGraphicalTheme.unicode());

  // you can relay on the toString default implementation of Diagnostic
  // which will use defaultReportHandler as the reporter
  {
    print(NewError());
  }
  // or you can do it manually
  {
    final buffer = StringBuffer();
    GraphicalReportHandler.newThemed(MigaGraphicalTheme.none()).report(NewError(), buffer);
    print(buffer);
  }
}
