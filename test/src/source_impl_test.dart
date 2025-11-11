import "dart:convert";
import "dart:typed_data";

import "package:miga/src/protocol.dart";
import "package:miga/src/source_impl.dart";
import "package:test/expect.dart";
import "package:test/scaffolding.dart";

void main() {
  test("basic", () {
    final contents = SourceCodeString("foo\n").readSpan(SourceSpan.simple(0, 4), 0, 0);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("foo\n"));
    expect(contents.line, equals(0));
    expect(contents.column, equals(0));
  });

  test("shifted", () {
    final contents = SourceCodeString("foobar").readSpan(SourceSpan.simple(3, 3), 1, 1);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("foobar"));
    expect(contents.line, equals(0));
    expect(contents.column, equals(0));
  });

  test("middle", () {
    final contents = SourceCodeString("foo\nbar\nbaz\n").readSpan(SourceSpan.simple(4, 4), 0, 0);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("bar\n"));
    expect(contents.line, equals(1));
    expect(contents.column, equals(0));
  });

  test("end of line", () {
    final contents = SourceCodeString("source\n  text\n    here").readSpan(SourceSpan.simple(6, 0), 1, 1);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("source\n  text\n"));
  });

  test("middle of line", () {
    final contents = SourceCodeString("foo\nbarbar\nbaz\n").readSpan(SourceSpan.simple(7, 4), 0, 0);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("bar\n"));
    expect(contents.line, equals(1));
    expect(contents.column, equals(3));
  });

  test("with crlf", () {
    final contents = SourceCodeString(
      "foo\r\nbar\r\nbaz\r\n",
    ).readSpan(SourceSpan.simple(5, 5), 0, 0);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("bar\r\n"));
    expect(contents.line, equals(1));
    expect(contents.column, equals(0));
  });

  test("with context", () {
    final contents = SourceCodeString(
      "xxx\nfoo\nbar\nbaz\n\nyyy\n",
    ).readSpan(SourceSpan.simple(8, 3), 1, 1);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("foo\nbar\nbaz\n"));
    expect(contents.line, equals(1));
    expect(contents.column, equals(0));
  });

  test("multiline with context", () {
    final contents = SourceCodeString(
      "aaa\nxxx\n\nfoo\nbar\nbaz\n\nyyy\nbbb\n",
    ).readSpan(SourceSpan.simple(9, 11), 1, 1);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("\nfoo\nbar\nbaz\n\n"));
    expect(contents.line, equals(2));
    expect(contents.column, equals(0));
    final span = SourceSpan.simple(8, 14);
    expect(contents.span, equals(span));
  });

  test("multiline with context line start", () {
    final contents = SourceCodeString(
      "one\ntwo\n\nthree\nfour\nfive\n\nsix\nseven\n",
    ).readSpan(SourceSpan.simple(2, 0), 2, 2);
    expect(utf8.decode(Uint8List.sublistView(contents.data)), equals("one\ntwo\n\n"));
    expect(contents.line, equals(0));
    expect(contents.column, equals(0));
    final span = SourceSpan.simple(0, 9);
    expect(contents.span, equals(span));
  });
}
