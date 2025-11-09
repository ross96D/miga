// ignore_for_file: prefer_double_quotes

import 'package:miga/src/protocol.dart';

class DebugReportHandler extends ReportHandler {
  @override
  void report(Diagnostic error, StringBuffer buffer) {
    buffer.write("DebugReportHandler\n");
    buffer.write("message: $error\n");
    if (error.code != null) buffer.write("code: ${error.code}\n");
    if (error.severity != null) buffer.write("severity: ${error.severity}\n");
    if (error.url != null) buffer.write("url: ${error.url}\n");
    if (error.help != null) buffer.write("help: ${error.help}\n");
    if (error.labels != null) buffer.write("labels: ${error.labels}\n");
    if (error.diagnosticSource != null) {
     buffer.write("caused by: ");
     report(error.diagnosticSource!, buffer);
    }
  }
}
