import "dart:convert";
import "dart:math";
import "dart:typed_data";

import "package:chalkdart/chalk.dart";
import "package:characters/characters.dart";
import "package:miga/src/%20highlighter/highlighter.dart";
import "package:miga/src/diagnostic_chain.dart";
import "package:miga/src/protocol.dart";
import "package:miga/src/utils.dart";
import "package:miga/src/utils/is_printable.dart";
import "package:textwrap/textwrap.dart" show TextWrapper;

/// Theme used by [GraphicalReportHandler] to
/// render fancy [Diagnostic] reports.
///
/// A theme consists of two things: the set of characters to be used for drawing,
/// and the set of [Chalk]'s from the chalkdart package to be used to paint various items.
///
/// You can create your own custom graphical theme using this type, or you can use
/// one of the predefined ones.
class MigaGraphicalTheme {
  /// Characters to be used for drawing.
  final MigaCharactersTheme characters;

  /// Styles to be used for painting.
  final MigaStyleTheme styles;

  MigaGraphicalTheme(this.styles, this.characters);

  factory MigaGraphicalTheme.defaults([Chalk? root]) {
    final env = String.fromEnvironment("NO_COLOR");
    if (env.isEmpty) {
      return MigaGraphicalTheme.unicode(root);
    } else {
      return MigaGraphicalTheme.unicodeNoColor(root);
    }
  }

  /// ASCII-art-based graphical drawing, with ANSI styling.
  MigaGraphicalTheme.ascii([Chalk? root])
    : characters = MigaCharactersTheme.ascii(),
      styles = MigaStyleTheme.ansi(root ?? Chalk());

  /// Graphical theme that draws using both ansi colors and unicode
  /// characters.
  ///
  /// Note that full rgb colors aren't enabled by default because they're
  /// an accessibility hazard, especially in the context of terminal themes
  /// that can change the background color and make hardcoded colors illegible.
  /// Such themes typically remap ansi codes properly, treating them more
  /// like CSS classes than specific colors.
  MigaGraphicalTheme.unicode([Chalk? root])
    : characters = MigaCharactersTheme.unicode(),
      styles = MigaStyleTheme.ansi(root ?? Chalk());

  /// Graphical theme that draws in monochrome, while still using unicode
  /// characters.
  MigaGraphicalTheme.unicodeNoColor([Chalk? root])
    : characters = MigaCharactersTheme.unicode(),
      styles = MigaStyleTheme.none(root ?? Chalk());

  MigaGraphicalTheme.none([Chalk? root])
    : characters = MigaCharactersTheme.ascii(),
      styles = MigaStyleTheme.none(root ?? Chalk());
}

class MigaStyleTheme {
  /// Style to apply to things highlighted as "error".
  final Chalk? error;

  /// Style to apply to things highlighted as "warning".
  final Chalk? warning;

  /// Style to apply to things highlighted as "advice".
  final Chalk? advice;

  /// Style to apply to the help text.
  final Chalk? help;

  /// Style to apply to filenames/links/URLs.
  final Chalk? link;

  /// Style to apply to line numbers.
  final Chalk? linum;

  /// Styles to cycle through to render the lines
  /// and text for diagnostic highlights.
  final List<Chalk?> highlights;

  const MigaStyleTheme({
    required this.error,
    required this.warning,
    required this.advice,
    required this.help,
    required this.link,
    required this.linum,
    required this.highlights,
  });

  MigaStyleTheme.rgb(Chalk parent)
    : error = parent.rgb(255, 30, 30),
      warning = parent.rgb(244, 191, 117),
      advice = parent.rgb(106, 159, 181),
      help = parent.rgb(106, 159, 181),
      link = parent.rgb(92, 157, 255).underlined.bold,
      linum = parent.dimGray,
      highlights = [parent.rgb(246, 87, 248), parent.rgb(30, 201, 212), parent.rgb(145, 246, 111)];

  MigaStyleTheme.ansi(Chalk parent)
    : error = parent.red,
      warning = parent.yellow,
      advice = parent.cyan,
      help = parent.cyan,
      link = parent.cyan.underlined.bold,
      linum = parent.dim,
      highlights = [parent.magenta, parent.yellow, parent.green];

  MigaStyleTheme.none(Chalk parent)
    : error = null,
      warning = null,
      advice = null,
      help = null,
      link = null,
      linum = null,
      highlights = [null];
}

class MigaCharactersTheme {
  String hbar;
  String vbar;
  String xbar;
  String vbarBreak;

  String uarrow;
  String rarrow;

  String ltop;
  String mtop;
  String rtop;
  String lbot;
  String rbot;
  String mbot;

  String lbox;
  String rbox;

  String lcross;
  String rcross;

  String underbar;
  String underline;

  String error;
  String warning;
  String advice;

  MigaCharactersTheme({
    required this.hbar,
    required this.vbar,
    required this.xbar,
    required this.vbarBreak,
    required this.uarrow,
    required this.rarrow,
    required this.ltop,
    required this.mtop,
    required this.rtop,
    required this.lbot,
    required this.rbot,
    required this.mbot,
    required this.lbox,
    required this.rbox,
    required this.lcross,
    required this.rcross,
    required this.underbar,
    required this.underline,
    required this.error,
    required this.warning,
    required this.advice,
  });

  MigaCharactersTheme.unicode()
    : hbar = "─",
      vbar = "│",
      xbar = "┼",
      vbarBreak = "·",
      uarrow = "▲",
      rarrow = "▶",
      ltop = "╭",
      mtop = "┬",
      rtop = "╮",
      lbot = "╰",
      mbot = "┴",
      rbot = "╯",
      lbox = "[",
      rbox = "]",
      lcross = "├",
      rcross = "┤",
      underbar = "┬",
      underline = "─",
      error = "×",
      warning = "⚠",
      advice = "☞";

  MigaCharactersTheme.emoji()
    : hbar = "─",
      vbar = "│",
      xbar = "┼",
      vbarBreak = "·",
      uarrow = "▲",
      rarrow = "▶",
      ltop = "╭",
      mtop = "┬",
      rtop = "╮",
      lbot = "╰",
      mbot = "┴",
      rbot = "╯",
      lbox = "[",
      rbox = "]",
      lcross = "├",
      rcross = "┤",
      underbar = "┬",
      underline = "─",
      error = "💥",
      warning = "⚠️",
      advice = "💡";

  MigaCharactersTheme.ascii()
    : hbar = "-",
      vbar = "|",
      xbar = "+",
      vbarBreak = ":",
      uarrow = "^",
      rarrow = ">",
      ltop = ",",
      mtop = "v",
      rtop = ".",
      lbot = "`",
      mbot = "^",
      rbot = "'",
      lbox = "[",
      rbox = "]",
      lcross = "|",
      rcross = "|",
      underbar = "|",
      underline = "^",
      error = "x",
      warning = "!",
      advice = ">";
}

enum MigaLinkStyle { none, link, text }

/// --------------------------- implementation part ---------------------------------------

class GraphicalReportHandler extends ReportHandler {
  final MigaLinkStyle links;

  final MigaGraphicalTheme theme;

  /// The 'global' footer for this handler.
  final String? footer;

  final int contextLines;

  /// Whether to include or not the cause chain of the top-level error in the graphical
  /// output.
  final bool withCauseChain;

  /// The width to wrap the report at.
  final int termWidth;

  final int tabWidth;

  /// Enables or disables wrapping of lines to fit the width.
  final bool wrapLines;

  /// Enables or disables breaking of words during wrapping.
  final bool breakWords;

  /// Sets the word separator to use when wrapping.
  final bool withPrimarySpanStart;

  final Highlighter highlighter;

  /// Display text for links. Displays `(link)` if this option is not set.
  final String? linkDisplayText;

  /// Whether to render related errors as nested errors.
  final bool showRelatedAsNested;

  GraphicalReportHandler._({
    required this.links,
    required this.theme,
    required this.footer,
    required this.contextLines,
    required this.withCauseChain,
    required this.termWidth,
    required this.tabWidth,
    required this.wrapLines,
    required this.breakWords,
    required this.withPrimarySpanStart,
    required this.highlighter,
    required this.linkDisplayText,
    required this.showRelatedAsNested,
  });

  factory GraphicalReportHandler() => GraphicalReportHandler._(
    links: MigaLinkStyle.link,
    termWidth: 200,
    theme: MigaGraphicalTheme.defaults(),
    footer: null,
    contextLines: 1,
    tabWidth: 4,
    withCauseChain: true,
    wrapLines: true,
    breakWords: true,
    withPrimarySpanStart: true,
    highlighter: BlankHighlighter(),
    linkDisplayText: null,
    showRelatedAsNested: false,
  );

  factory GraphicalReportHandler.newThemed(MigaGraphicalTheme theme) => GraphicalReportHandler._(
    links: MigaLinkStyle.link,
    termWidth: 200,
    theme: theme,
    footer: null,
    contextLines: 1,
    tabWidth: 4,
    withCauseChain: true,
    wrapLines: true,
    breakWords: true,
    withPrimarySpanStart: true,
    highlighter: BlankHighlighter(),
    linkDisplayText: null,
    showRelatedAsNested: false,
  );

  GraphicalReportHandler copyWith({
    required String? footer,
    required String? linkDisplayText,
    MigaLinkStyle? links,
    MigaGraphicalTheme? theme,
    int? contextLines,
    bool? withCauseChain,
    int? termWidth,
    int? tabWidth,
    bool? wrapLines,
    bool? breakWords,
    bool? withPrimarySpanStart,
    Highlighter? highlighter,
    bool? showRelatedAsNested,
  }) {
    return GraphicalReportHandler._(
      links: links ?? this.links,
      theme: theme ?? this.theme,
      footer: footer,
      contextLines: contextLines ?? this.contextLines,
      withCauseChain: withCauseChain ?? this.withCauseChain,
      termWidth: termWidth ?? this.termWidth,
      tabWidth: tabWidth ?? this.tabWidth,
      wrapLines: wrapLines ?? this.wrapLines,
      breakWords: breakWords ?? this.breakWords,
      withPrimarySpanStart: withPrimarySpanStart ?? this.withPrimarySpanStart,
      highlighter: highlighter ?? this.highlighter,
      linkDisplayText: linkDisplayText,
      showRelatedAsNested: showRelatedAsNested ?? this.showRelatedAsNested,
    );
  }

  @override
  void report(Diagnostic diagnostic, StringBuffer buffer) {
    renderReportInner(diagnostic, diagnostic.sourceCode, buffer);
  }

  void renderReportInner(Diagnostic diagnostic, SourceCode? parentSource, StringBuffer buffer) {
    final source = diagnostic.sourceCode ?? parentSource;
    renderHeader(diagnostic, buffer, false);
    renderCauses(diagnostic, source, buffer);
    renderSnippets(diagnostic, source, buffer);
    renderFooter(diagnostic, buffer);
    // renderRelated()
    if (footer != null) {
      buffer.writeln();
      final width = max(termWidth - 2, 0);
      final lines = TextWrapper(
        width: width,
        initialIndent: "  ",
        subsequentIndent: "  ",
        breakLongWords: breakWords,
      ).wrap(footer!);
      for (final line in lines) {
        buffer.writeln(line);
      }
    }
  }

  void renderCauses(Diagnostic diagnostic, SourceCode? parentSource, StringBuffer buffer) {
    final source = parentSource ?? diagnostic.sourceCode;

    final (severityStyle, severityIcon) = switch (diagnostic.severity) {
      Severity.error || null => (theme.styles.error, theme.characters.error),
      Severity.warning => (theme.styles.warning, theme.characters.warning),
      Severity.advice => (theme.styles.advice, theme.characters.advice),
    };

    final width = max(termWidth - 2, 0);
    final lines = TextWrapper(
      width: width,
      initialIndent: "  ${severityIcon.style(severityStyle)} ",
      subsequentIndent: "  ${theme.characters.vbar.style(severityStyle)} ",
      breakLongWords: breakWords,
    ).wrap(diagnostic.display());

    for (final line in lines) {
      buffer.writeln(line);
    }

    if (!withCauseChain) return;

    final chain = DiagnosticChain(diagnostic.diagnosticSource);
    for (final cause in chain.iter()) {
      final isLast = chain.peek() == null;
      final char = !isLast ? theme.characters.lcross : theme.characters.lbot;

      final initialIdent = "  $char${theme.characters.hbar}${theme.characters.rarrow} ".style(
        severityStyle,
      );
      final restIdent = "  ${isLast ? ' ' : theme.characters.vbar}   ".style(severityStyle);
      final innerRenderer = copyWith(
        footer: null,
        linkDisplayText: linkDisplayText,
        withCauseChain: false,
        termWidth: termWidth - Characters(restIdent).length,
      );
      final inner = StringBuffer();
      innerRenderer.renderReportInner(cause, source, inner);

      var innerString = inner.toString();
      if (innerString.startsWith("\n")) {
        innerString = innerString.replaceFirst("\n", "");
      }
      bool isFirst = true;
      // TODO 2: maybe split by "\n" is not the best solution
      for (final line in innerString.split("\n")) {
        if (line.isEmpty) {
          buffer.writeln();
          continue;
        }
        buffer.writeln("${isFirst ? initialIdent : restIdent}$line");
        isFirst = false;
      }
    }
  }

  void renderHeader(Diagnostic diagnostic, StringBuffer buffer, bool isNested) {
    final severityStyle = switch (diagnostic.severity) {
      Severity.error || null => theme.styles.error,
      Severity.warning => theme.styles.warning,
      Severity.advice => theme.styles.advice,
    };
    final header = StringBuffer();
    var needsNewline = isNested;

    if (links == MigaLinkStyle.link && diagnostic.url != null) {
      final url = diagnostic.url!;
      final code = diagnostic.code?.toString() ?? "";

      final displayText = linkDisplayText ?? "(link)";
      final link =
          "\u{1b}]8;;$url\u{1b}\\${code.style(severityStyle)}${displayText.style(theme.styles.link)}\u{1b}]8;;\u{1b}\\";

      header.write(link);
      buffer.write(header);
      needsNewline = true;
    } else if (diagnostic.code != null) {
      header.write("${diagnostic.code}".style(severityStyle));
      if (links == MigaLinkStyle.text && diagnostic.url != null) {
        header.write(" (${diagnostic.url!.style(theme.styles.link)})");
      }
      buffer.writeln(header);
      needsNewline = true;
    }

    if (needsNewline) {
      buffer.writeln();
    }
  }

  void renderFooter(Diagnostic diagnostic, StringBuffer buffer) {
    if (diagnostic.help == null) return;

    final width = max(termWidth - 2, 0);
    final initialIdent = "  help: ".style(theme.styles.help);

    final lines = TextWrapper(
      width: width,
      initialIndent: initialIdent,
      subsequentIndent: "        ",
      breakLongWords: breakWords,
    ).wrap(diagnostic.help!);

    for (final line in lines) {
      buffer.writeln(line);
    }
  }

  void renderSnippets(Diagnostic diagnostic, SourceCode? source, StringBuffer buffer) {
    if (source == null) return;
    if (diagnostic.labels == null) return;

    final labels = diagnostic.labels!.toList()..sort((a, b) => a.offset - b.offset);

    final contexts = <(LabeledSourceSpan, SpanContents)>[];
    for (final right in labels) {
      final rightConts = source.readSpan(right, contextLines, contextLines);
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

    final contextLabels = labels.where((label) {
      return context.offset <= label.offset &&
          label.offset + label.length <= context.offset + context.length;
    });

    final primaryLabel = contextLabels.isNotEmpty
        ? contextLabels.firstWhere((l) => l.primary, orElse: () => contextLabels.first)
        : null;

    final labelsSpans = labels.zip2(theme.styles.highlights.cycle()).map((entry) {
      final label = entry.$1;
      final style = entry.$2;
      return FancySpan(label, style, splitLabel(label.label));
    }).toList();

    final highlighterState = highlighter.startHighlighterState(contents);

    // The max number of gutter-lines that will be active at any given
    // point. We need this to figure out indentation, so we do one loop
    // over the lines to see what the damage is gonna be.
    var maxGutter = 0;
    for (final line in lines) {
      var numHighlights = 0;
      for (final hl in labelsSpans) {
        if (!line.spanLineOnly(hl) && line.spanAppliesGutter(hl)) {
          numHighlights += 1;
        }
      }
      maxGutter = max(maxGutter, numHighlights);
    }

    // Oh and one more thing: We need to figure out how much room our line
    // numbers need!
    final linumWidth = (lines.lastOrNull?.lineNumber ?? 0).toString().length;

    buffer.write("${' ' * (linumWidth + 2)}${theme.characters.ltop}${theme.characters.hbar}");

    final primaryContent = switch (primaryLabel) {
      LabeledSourceSpan v => source.readSpan(v, 0, 0),
      null => contents,
    };

    if (primaryContent.name != null) {
      if (withPrimarySpanStart) {
        final txt =
            "${primaryContent.name}:${primaryContent.line + 1}:${primaryContent.column + 1}";
        buffer.writeln("[${txt.style(theme.styles.link)}]");
      } else {
        buffer.writeln("[${primaryContent.name!.style(theme.styles.link)}]");
      }
    } else if (withPrimarySpanStart && lines.length > 1) {
      buffer.writeln("[${primaryContent.line + 1}:${primaryContent.column + 1}]");
    } else {
      buffer.writeln(theme.characters.hbar * 3);
    }

    // Now it's time for the fun part--actually rendering everything!
    for (final line in lines) {
      // Line number, appropriately padded.
      writeLinum(linumWidth, line.lineNumber, buffer);

      // Then, we need to print the gutter, along with any fly-bys We
      // have separate gutters depending on whether we're on the actual
      // line, or on one of the "highlight lines" below it.
      _renderLineGutter(maxGutter, line, labelsSpans, buffer);

      final styledText = highlighterState.highlightLine(line.text);
      renderLineText(styledText, buffer);

      final singleLine = <FancySpan>[];
      final multiLine = <FancySpan>[];
      for (final hl in labelsSpans) {
        if (line.spanApplies(hl)) {
          if (line.spanLineOnly(hl)) {
            singleLine.add(hl);
          } else {
            multiLine.add(hl);
          }
        }
      }
      if (singleLine.isNotEmpty) {
        // no line number!
        writeNoLinum(linumWidth, buffer);
        // gutter _again_
        renderHighlightGutter(maxGutter, line, labelsSpans, LabelRenderMode.singleLine, buffer);
        renderSingleLineHighlights(line, linumWidth, maxGutter, singleLine, labelsSpans, buffer);
      }

      for (final hl in multiLine) {
        if (hl.label != null && line.spanEnds(hl) && !line.spanStarts(hl)) {
          _renderMultilineEnd(labelsSpans, maxGutter, linumWidth, line, hl, buffer);
        }
      }
    }

    buffer.writeln("${' ' * (linumWidth + 2)}${theme.characters.lbot}${theme.characters.hbar * 4}");
  }

  void _renderMultilineEnd(
    Iterable<FancySpan> labels,
    int maxGutter,
    int linumWidth,
    _Line line,
    FancySpan label,
    StringBuffer buffer,
  ) {
    writeNoLinum(linumWidth, buffer);
    final labelParts = label.labelParts();

    if (labelParts == null) {
      renderHighlightGutter(maxGutter, line, labels, LabelRenderMode.singleLine, buffer);
      buffer.write(theme.characters.hbar.style(label.style));
      return;
    }

    final first = labelParts.first;
    final rest = labelParts.sublist(1);

    final renderMode = rest.isEmpty ? LabelRenderMode.singleLine : LabelRenderMode.multiLineFirst;
    renderHighlightGutter(maxGutter, line, labels, renderMode, buffer);
    renderMultiLineEndSingle(first, label.style, renderMode, buffer);

    for (final labelLine in rest) {
      writeNoLinum(linumWidth, buffer);
      renderHighlightGutter(maxGutter, line, labels, LabelRenderMode.multiLineRest, buffer);
      renderMultiLineEndSingle(labelLine, label.style, LabelRenderMode.multiLineRest, buffer);
    }
  }

  void _renderLineGutter(
    int maxGutter,
    _Line line,
    Iterable<FancySpan> highlights,
    StringBuffer buffer,
  ) {
    if (maxGutter == 0) return;

    final chars = theme.characters;
    var gutter = StringBuffer();
    final applicable = highlights.where((hl) => line.spanAppliesGutter(hl));
    var arrow = false;

    var i = -1;
    for (final hl in applicable) {
      i += 1;

      if (line.spanStarts(hl)) {
        gutter.write(chars.ltop.style(hl.style));
        gutter.write((chars.hbar * (max(maxGutter - i, 0))).style(hl.style));
        gutter.write(chars.rarrow.style(hl.style));
        arrow = true;
        break;
      } else if (line.spanEnds(hl)) {
        if (hl.label != null) {
          gutter.write(chars.lcross.style(hl.style));
        } else {
          gutter.write(chars.lbot.style(hl.style));
        }
        gutter.write((chars.hbar * (max(maxGutter - i, 0))).style(hl.style));
        gutter.write(chars.rarrow.style(hl.style));
        arrow = true;
        break;
      } else if (line.spanFlyby(hl)) {
        gutter.write(chars.vbar.style(hl.style));
      } else {
        gutter.write(" ");
      }
    }

    final gutterStr = gutter.toString();
    final rigthPad = " " * ((arrow ? 1 : 3) + max(maxGutter - (gutterStr.runes.length), 0));
    buffer.write("$gutterStr$rigthPad");
  }

  void renderLineText(String text, StringBuffer buffer) {
    final inner = StringBuffer();
    for (final (char, width) in Characters(text).zip2(lineVisualCharWidth(text))) {
      if (char == "\t") {
        inner.write(" " * width);
      } else {
        inner.write(char);
      }
    }
    inner.writeCharCode(10); // write \n
    buffer.write(inner);
  }

  void renderHighlightGutter(
    int maxGutter,
    _Line line,
    Iterable<FancySpan> highlights,
    LabelRenderMode renderMode,
    StringBuffer buffer,
  ) {
    if (maxGutter == 0) return;

    // keeps track of how many columns wide the gutter is
    // important for ansi since simply measuring the size of the final string
    // gives the wrong result when the string contains ansi codes.
    var gutterCols = 0;
    final chars = theme.characters;
    var gutter = StringBuffer();
    final applicable = highlights.where((hl) => line.spanAppliesGutter(hl));

    var i = -1;
    for (final hl in applicable) {
      i += 1;
      // if !line.span_line_only(hl) && line.span_ends(hl) {}
      if (!line.spanLineOnly(hl) && line.spanEnds(hl)) {
        // if render_mode == LabelRenderMode::MultiLineRest {
        if (renderMode == LabelRenderMode.multiLineRest) {
          // this is to make multiline labels work. We want to make the right amount
          // of horizontal space for them, but not actually draw the lines
          final horizontalSpace = max(maxGutter - i, 0) + 2;
          gutter.write(" " * horizontalSpace);
          // account for one more horizontal space, since in multiline mode
          // we also add in the vertical line before the label like this:
          // 2 │ ╭─▶   text
          // 3 │ ├─▶     here
          //   · ╰──┤ these two lines
          //   ·    │ are the problem
          //        ^this
          gutterCols += horizontalSpace + 1;
        } else {
          // et num_repeat = max_gutter.saturating_sub(i) + 2;
          final numRepeat = max(maxGutter - i, 0) + 2;
          final numRepeatHbar = numRepeat - (renderMode == LabelRenderMode.multiLineFirst ? 1 : 0);
          gutter.write(chars.lbot.style(hl.style));

          gutter.write((chars.hbar * numRepeatHbar).style(hl.style));
          // we count 1 for the lbot char, and then a few more, the same number
          // as we just repeated for. For each repeat we only add 1, even though
          // due to ansi escape codes the number of bytes in the string could grow
          // a lot each time.
          gutterCols += numRepeat + 1;
        }
        break;
      } else {
        gutter.write(chars.vbar.style(hl.style));
        // we may push many bytes for the ansi escape codes style adds,
        // but we still only add a single character-width to the string in a terminal
        gutterCols += 1;
      }
    }

    // now calculate how many spaces to add based on how many columns we just created.
    // it's the max width of the gutter, minus how many character-widths we just generated
    // capped at 0 (though this should never go below in reality), and then we add 3 to
    // account for arrowheads when a gutter line ends
    final numSpaces = max((maxGutter + 3) - gutterCols, 0);
    // we then write the gutter and as many spaces as we need
    buffer.write(gutter.toString() + " " * numSpaces);
  }

  void renderSingleLineHighlights(
    _Line line,
    int linumWidth,
    int maxGutter,
    List<FancySpan> singleLiners,
    List<FancySpan> allHighlights,
    StringBuffer buffer,
  ) {
    var highest = 0;

    final chars = theme.characters;
    final vbarOffsets = singleLiners.map((hl) {
      final byteStart = hl.offset;
      final byteEnd = hl.offset + hl.length;
      final start = max(visualOffset(line, byteStart, true), highest);

      final end = hl.length == 0 ? start + 1 : max(visualOffset(line, byteEnd, false), start + 1);

      final vbarOffset = ((start + end) / 2).floor();
      final numLeft = vbarOffset - start;
      final numRight = end - vbarOffset - 1;

      final String secondChar;
      if (hl.length == 0) {
        secondChar = chars.uarrow;
      } else if (hl.label != null) {
        secondChar = chars.underbar;
      } else {
        secondChar = chars.underline;
      }
      final initialPad = "".padRight(max(start - highest, 0));
      buffer.write(
        "$initialPad${chars.underline * numLeft}$secondChar${chars.underline * numRight}".style(
          hl.style,
        ),
      );

      highest = max(highest, end);

      return (hl, vbarOffset);
    }).toList();
    buffer.writeln();

    for (final hl in singleLiners.reversed) {
      final labelParts = hl.labelParts();
      if (labelParts == null) {
        continue;
      }
      var first = true;
      for (final labelLine in labelParts) {
        final renderMode = first
            ? (labelParts.length == 1 ? LabelRenderMode.singleLine : LabelRenderMode.multiLineFirst)
            : LabelRenderMode.multiLineRest;

        writeLabelText(
          line,
          linumWidth,
          maxGutter,
          allHighlights,
          chars,
          vbarOffsets,
          hl,
          labelLine,
          renderMode,
          buffer,
        );
        first = false;
      }
    }
  }

  void renderMultiLineEndSingle(
    String label,
    Chalk? style,
    LabelRenderMode renderMode,
    StringBuffer buffer,
  ) {
    switch (renderMode) {
      case LabelRenderMode.singleLine:
        buffer.writeln("${theme.characters.hbar.style(style)} $label");
      case LabelRenderMode.multiLineFirst:
        buffer.writeln("${theme.characters.rcross.style(style)} $label");
      case LabelRenderMode.multiLineRest:
        buffer.writeln("${theme.characters.vbar.style(style)} $label");
    }
  }

  /// Returns the visual column position of a byte offset on a specific line.
  ///
  /// If the offset occurs in the middle of a character, the returned column
  /// corresponds to that character's first column in `start` is true, or its
  /// last column if `start` is false.
  int visualOffset(_Line line, int offset, bool start) {
    final lineRange = List.generate(line.length + 1, (i) => line.offset + i);
    assert(lineRange.contains(offset));

    var bytesIdx = offset - line.offset;
    // TODO 3: we could optimize this to avoid the utf8.encode call that suffer a copy penalty
    // and instead use utf8ByteLength function from utils and iterate over the runes instead
    // of iterating over the bytes
    final bytes = utf8.encode(line.text);
    while (bytesIdx <= bytes.length && bytesIdx >= 0 && !isCharBoundary(bytes, bytesIdx)) {
      if (start) {
        bytesIdx -= 1;
      } else {
        bytesIdx += 1;
      }
    }
    final bytesSublist = bytes.sublist(0, bytesIdx.clamp(0, bytes.length));
    var textWidth = lineVisualCharWidth(utf8.decode(bytesSublist)).reduceSafe((a, b) => a + b) ?? 0;
    if (bytesIdx > bytes.length) {
      // Spans extending past the end of the line are always rendered as
      // one column past the end of the visible line.
      //
      // This doesn't necessarily correspond to a specific byte-offset,
      // since a span extending past the end of the line could contain:
      //  - an actual \n character (1 byte)
      //  - a CRLF (2 bytes)
      //  - EOF (0 bytes)
      return textWidth + 1;
    } else {
      return textWidth;
    }
  }

  void writeLabelText(
    _Line line,
    int linumWidth,
    int maxGutter,
    List<FancySpan> allHl,
    MigaCharactersTheme chars,
    List<(FancySpan, int)> vbarOffsets,
    FancySpan hl,
    String label,
    LabelRenderMode renderMode,
    StringBuffer buffer,
  ) {
    writeNoLinum(linumWidth, buffer);
    renderHighlightGutter(maxGutter, line, allHl, LabelRenderMode.singleLine, buffer);

    var currOffset = 1;
    for (final (offsetHl, vbarOffset) in vbarOffsets) {
      while (currOffset < vbarOffset + 1) {
        buffer.write(" ");
        currOffset += 1;
      }
      if (offsetHl != hl) {
        buffer.write(chars.vbar.style(offsetHl.style));
        currOffset += 1;
      } else {
        final lines = switch (renderMode) {
          LabelRenderMode.singleLine => "${chars.lbot}${chars.hbar * 2} $label",
          LabelRenderMode.multiLineFirst => "${chars.lbot}${chars.hbar}${chars.rcross} $label",
          LabelRenderMode.multiLineRest => "  ${chars.vbar} $label",
        };
        buffer.writeln(lines.style(hl.style));
        break;
      }
    }
  }

  void writeLinum(int width, int linum, StringBuffer buffer) {
    final linumStr = linum.toString().padRight(width).style(theme.styles.linum);
    buffer.write(" $linumStr ${theme.characters.vbar} ");
  }

  void writeNoLinum(int width, StringBuffer buffer) {
    buffer.write(" ${''.padRight(width)} ${theme.characters.vbarBreak} ");
  }

  Iterable<int> lineVisualCharWidth(String text) sync* {
    var column = 0;
    var escaped = false;

    for (final char in Characters(text)) {
      var width = 0;
      switch ((escaped, char)) {
        case (false, "\t"):
          width = tabWidth - column % tabWidth;
        case (false, "\x1b"):
          escaped = true;
          width = 0;
        case (false, _):
          if (char.length > 1) {
            width = char.length;
          } else {
            width = isPrintable(char.codeUnitAt(0)) ? 1 : 0;
          }
        case (true, "m"):
          escaped = false;
          width = 0;
        case (true, _):
          width = 0;
      }
      column += width;
      yield width;
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
          _Line(
            lineNumber: line,
            offset: lineOffset,
            text: lineStr.toString(),
            length: offset - lineOffset,
          ),
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
  final int lineNumber;
  final int offset;
  final int length;
  final String text;

  _Line({required this.lineNumber, required this.offset, required this.length, required this.text});

  bool spanLineOnly(FancySpan span) {
    return span.offset >= offset && span.offset + span.length <= offset + length;
  }

  /// Returns whether `span` should be visible on this line, either in the gutter or under the
  /// text on this line
  bool spanApplies(FancySpan span) {
    final spanLen = span.length == 0 ? 1 : span.length;

    return (span.offset >= offset && span.offset < offset + length) ||
        // Span passes through this line
        (span.offset < offset && span.offset + spanLen > offset + length) || //todo
        // Span ends on this line
        (span.offset + spanLen > offset && span.offset + spanLen <= offset + length);
  }

  /// Returns whether `span` should be visible on this line in the gutter (so this excludes spans
  /// that are only visible on this line and do not span multiple lines)
  bool spanAppliesGutter(FancySpan span) {
    final spanLen = span.length == 0 ? 1 : span.length;

    return spanApplies(span) &&
        !(
        // as long as it doesn't start *and* end on this line
        (span.offset >= offset && span.offset < offset + length) &&
            (span.offset + spanLen > offset && span.offset + spanLen <= offset + length));
  }

  // A 'flyby' is a multi-line span that technically covers this line, but
  // does not begin or end within the line itself. This method is used to
  // calculate gutters.
  bool spanFlyby(FancySpan span) {
    return span.offset < offset &&
        // ...and it stops after this line's end.
        span.offset + span.length > offset + length;
  }

  // Does this line contain the *beginning* of this multiline span?
  // This assumes self.spanApplies() is true already.
  bool spanStarts(FancySpan span) {
    return span.offset >= offset;
  }

  // Does this line contain the *end* of this multiline span?
  // This assumes self.spanApplies() is true already.
  bool spanEnds(FancySpan span) {
    return span.offset + span.length >= offset && span.offset + span.length <= offset + length;
  }
}

class FancySpan {
  final List<String>? label;
  final SourceSpan span;
  final Chalk? style;

  int get offset => span.offset;

  int get length => span.length;

  FancySpan(this.span, this.style, this.label);

  List<String>? labelParts() {
    if (label == null) return null;
    return _labelParts().toList();
  }

  Iterable<String> _labelParts() sync* {
    assert(label != null);
    for (final l in label!) {
      yield l.style(style);
    }
  }
}

List<String>? splitLabel(String? v) {
  if (v == null) return null;
  return v.split("\n");
}

enum LabelRenderMode {
  /// we're rendering a single line label (or not rendering in any special way)
  singleLine,

  /// we're rendering a multiline label
  multiLineFirst,

  /// we're rendering the rest of a multiline label
  multiLineRest,
}

extension on String {
  String style(Chalk? style) {
    return style?.call(this) ?? this;
  }
}
