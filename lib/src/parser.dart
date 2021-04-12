import 'dart:core';
import 'dart:math';

import 'ast.dart';
import 'error.dart';

class FluentParser {
  // This regex is used to iterate through the beginnings of messages and terms.
  // With the multiLine flag, the ^ matches at the beginning of every line.
  final reMessageStart = RegExp(r"^(-?[a-zA-Z][\w-]*) *= *", multiLine: true, dotAll: true);
  // Both Attributes and Variants are parsed in while loops. These regexes are
  // used to break out of them.
  final reAttributeStart = RegExp(
    r"\.([a-zA-Z][\w-]*) *= *",
  );
  final reVariantStart = RegExp(
    r"\*?\[",
  );

  final reNumberLiteral = RegExp(
    r"(-?[0-9]+(?:\.([0-9]+))?)",
  );
  final reIdentifier = RegExp(
    r"([a-zA-Z][\w-]*)",
  );
  final reReference = RegExp(
    r"([$-])?([a-zA-Z][\w-]*)(?:\.([a-zA-Z][\w-]*))?",
  );
  final reFunctionName = RegExp(
    r"^[A-Z][A-Z0-9_-]*$",
  );

  // A "run" is a sequence of text or string literal characters which don't
  // require any special handling. For TextElements such special characters are: {
  // (starts a placeable), and line breaks which require additional logic to check
  // if the next line is indented. For StringLiterals they are: \ (starts an
  // escape sequence), " (ends the literal), and line breaks which are not allowed
  // in StringLiterals. Note that string runs may be empty; text runs may not.
  final reTextRun = RegExp(
    r"([^{}\n\r]+)",
  );
  final reStringRun = RegExp(
    r'([^\\"\n\r]*)',
  );

  final reStringEscape = RegExp(
    r'\\([\\"])',
  );
  final reUnicodeEscape = RegExp(
    r"\\u([a-fA-F0-9]{4})|\\U([a-fA-F0-9]{6})",
  );

  // Used for trimming TextElements and indents.
  final reLeadingNewlines = RegExp(
    r'^\n+',
  );
  final reTrailingSpaces = RegExp(
    r' +$',
  );
  // Used in makeIndent to strip spaces from blank lines and normalize CRLF to LF.
  final reBlankLines = RegExp(r' *\r?\n', dotAll: true);
  // Used in makeIndent to measure the indentation.
  final reIndent = RegExp(
    r'( *)$',
  );

  // Common tokens.
  final tokenBraceOpen = RegExp(
    r'{\s*',
  );
  final tokenBraceClose = RegExp(
    r'\s*}',
  );
  final tokenBracketOpen = RegExp(
    r'\[\s*',
  );
  final tokenBracketClose = RegExp(
    r'\s*] *',
  );
  final tokenParenOpen = RegExp(
    r'\s*\(\s*',
  );
  final tokenArrow = RegExp(
    r'\s*->\s*',
  );
  final tokenColon = RegExp(
    r'\s*:\s*',
  );
  // Note the optional comma. As a deviation from the Fluent EBNF, the parser
  // doesn't enforce commas between call arguments.
  final tokenComma = RegExp(
    r'\s*,?\s*',
  );
  final tokenBlank = RegExp(
    r'\s+',
  );

  String source;
  int cursor = 0;
  FluentParser(this.source);

  Resource parse() {
    cursor = 0;
    // Iterate over the beginnings of messages and terms to efficiently skip
    // comments and recover from errors.
    Resource resource = Resource();
    for (RegExpMatch match in reMessageStart.allMatches(source)) {
      String id = match.group(1)!; // null-safety !
      cursor = match.end;
      try {
        resource.body.add(parseMessage(id));
      } on SyntaxError catch (e) {
        // Don't report any Fluent syntax errors. Skip directly to the
        // beginning of the next message or term.
        print(e);
        continue;
      } catch (err) {
        throw err;
      }
    }
    return resource;
  }

  Message parseMessage(String id) {
    final value = parsePattern();
    final attributes = parseAttributes();
    if (value == null && attributes.length == 0) {
      throw SyntaxError("Expected message value or attributes");
    }
    return Message(id, value!, attributes); // null-safety !
  }

  Map<String, Pattern> parseAttributes() {
    Map<String, Pattern> attrs = {};
    while (test(reAttributeStart)) {
      String name = match1(reAttributeStart)!; // null-safety !
      Pattern? value = parsePattern();
      if (value == null) {
        throw SyntaxError("Expected attribute value");
      }
      attrs[name] = value;
    }
    return attrs;
  }

  Pattern? parsePattern() {
    String? first;
    // First try to parse any simple text on the same line as the id.
    if (test(reTextRun)) {
      first = match1(reTextRun);
    }

    // If there's a placeable on the first line, parse a complex pattern.
    if (currentChar() == "{" || currentChar() == "}") {
      // Re-use the text parsed above, if possible.
      return parsePatternElements(first != null ? [TextElement(first)] : [], 65536);
    }
    // RE_TEXT_VALUE stops at newlines. Only continue parsing the pattern if
    // what comes after the newline is indented.
    Indent? indent = parseIndent();
    if (indent != null) {
      if (first != null) {
        // If there's text on the first line, the blank block is part of the
        // translation content in its entirety.
        return parsePatternElements([TextElement(first), indent], indent.length);
      }
      // Otherwise, we're dealing with a block pattern, i.e. a pattern which
      // starts on a new line. Discrad the leading newlines but keep the
      // inline indent; it will be used by the dedentation logic.
      indent.value = trim(indent.value, reLeadingNewlines);
      return parsePatternElements([indent], indent.length);
    }
    if (first != null) {
      // It was just a simple inline text after all.
      return Pattern([TextElement(trim(first, reTrailingSpaces))]);
    }
    return null;
  }

  Pattern parsePatternElements(List<PatternElement> elements, int commonIndent) {
    while (true) {
      if (test(reTextRun)) {
        String? text = match1(reTextRun); // null-safety !
        elements.add(TextElement(text!));
        continue;
      }

      if (currentChar() == "{") {
        elements.add(parsePlaceable());
        continue;
      }

      if (currentChar() == "}") {
        throw SyntaxError("Unbalanced closing brace");
      }

      final indent = parseIndent();
      if (indent != null) {
        elements.add(indent);
        commonIndent = min(commonIndent, indent.length);
        continue;
      }
      break;
    }

    final lastElement = elements.last;
    // Trim the trailing spaces in the last element if it's a TextElement.
    if (lastElement is TextElement) {
      lastElement.value = trim(lastElement.value, reTrailingSpaces);
    }

    List<PatternElement> baked = [];
    for (var element in elements) {
      if (element is Indent) {
        // Dedent indented lines by the maximum common indent.
        element.value = element.value.substring(0, element.value.length - commonIndent);
        if (element.value.length > 0) {
          baked.add(element);
        }
      } else {
        baked.add(element);
      }
    }
    return Pattern(baked);
  }

  Expression parsePlaceable() {
    consumeToken(tokenBraceOpen, true);

    final selector = parseInlineExpression();
    if (consumeToken(tokenBraceClose)) {
      return selector;
    }
    if (consumeToken(tokenArrow)) {
      List<Variant> variants = parseVariants();
      consumeToken(tokenBraceClose, true);
      return SelectExpression(selector, variants);
    }
    throw SyntaxError("Unclosed placeable");
  }

  Expression parseInlineExpression() {
    if (currentChar() == "{") {
      // It's a nested placeable.
      return parsePlaceable();
    }
    if (test(reReference)) {
      Match m = match(reReference);
      String? sigil = m.group(1);
      String? name = m.group(2)!;
      String? attr = m.group(3);

      if (sigil == "\$") {
        return VariableReference(name);
      }

      if (consumeToken(tokenParenOpen)) {
        final args = parseArguments();

        if (sigil == "-") {
          // A parameterized term: -term(...).
          return TermReference("-$name", attr, args);
        }
        if (reFunctionName.hasMatch(name)) {
          return FunctionReference(name, args);
        }

        throw SyntaxError("Function names must be all upper-case");
      }

      if (sigil == "-") {
        // A non-parameterized term: -term.
        return TermReference("-$name", attr);
      }

      return MessageReference(name, attr);
    }

    return parseLiteral();
  }

  List<Argument> parseArguments() {
    List<Argument> args = [];
    while (true) {
      if (currentChar() == null) {
        throw SyntaxError("Unclosed argument list");
      }
      // End of the argument list.
      else if (currentChar() == ")") {
        cursor++;
        return args;
      }

      args.add(parseArgument());
      // Commas between arguments are treated as whitespace.
      consumeToken(tokenComma);
    }
  }

  Argument parseArgument() {
    final expr = parseInlineExpression();
    if (expr is MessageReference) {
      if (consumeToken(tokenColon)) {
        // The reference is the beginning of a named argument.
        final value = parseLiteral();
        return NamedArgument(expr.name, value);
      }

      // It's a regular message reference.
      return PositionalArgument(expr);
    } else {
      return PositionalArgument(expr);
    }
  }

  List<Variant> parseVariants() {
    List<Variant> variants = [];
    bool hasStar = false;
    while (test(reVariantStart)) {
      bool isDefault = consumeChar("*");
      hasStar = hasStar || isDefault;
      final key = parseVariantKey();
      final value = parsePattern();
      if (value == null) {
        throw SyntaxError("Expected variant value");
      }
      variants.add(Variant(key, value, isDefault));
    }
    if (!hasStar) {
      throw SyntaxError("Expected default variant");
    }
    return variants;
  }

  Literal parseVariantKey() {
    consumeToken(tokenBracketOpen, true);
    Literal key;
    if (test(reNumberLiteral)) {
      key = parseNumberLiteral();
    } else {
      String value = match1(reIdentifier)!; // null-safety !
      key = StringLiteral(value);
    }
    consumeToken(tokenBracketClose, true);
    return key;
  }

  Literal parseLiteral() {
    if (test(reNumberLiteral)) {
      return parseNumberLiteral();
    }

    if (currentChar() == '"') {
      return parseStringLiteral();
    }

    throw SyntaxError("Invalid expression");
  }

  NumberLiteral parseNumberLiteral() {
    Match m = match(reNumberLiteral);
    String value = m.group(1)!; // null-safety !
    String fraction = m.group(2) ?? "";
    int precision = fraction.length;
    return NumberLiteral(precision == 0 ? int.parse(value) : double.parse(value), precision);
  }

  StringLiteral parseStringLiteral() {
    consumeChar('"', true);
    StringBuffer sb = StringBuffer();
    while (true) {
      String? value = match1(reStringRun);
      sb.write(value);

      if (currentChar() == null) {
        // We've reached an EOL of EOF.
        throw SyntaxError("Unclosed string literal");
      }
      if (currentChar() == "\\") {
        sb.write(parseEscapeSequence());
        continue;
      }
      if (consumeChar('"')) {
        return StringLiteral(sb.toString());
      }
    }
  }

  String? parseEscapeSequence() {
    if (test(reStringEscape)) {
      return match1(reStringEscape);
    }

    if (test(reUnicodeEscape)) {
      Match m = match(reUnicodeEscape);
      String? codepoint4 = m.group(1);
      String? codepoint6 = m.group(2);

      int codepoint = int.parse(codepoint4 ?? codepoint6 ?? '', radix: 16); //debug: can this '' cause issues ?

      return codepoint <= 0xd7ff || 0xe000 <= codepoint
          // It's a Unicode scalar value.
          ? String.fromCharCode(codepoint)
          // Lonely surrogates can cause trouble when the parsing result is
          // saved using UTF-8. Use U+FFFD REPLACEMENT CHARACTER instead.
          : "�";
    }

    throw SyntaxError("Unknown escape sequence");
  }

  // Parse blank space. Return it if it looks like indent before a pattern
  // line. Skip it othwerwise.
  Indent? parseIndent() {
    int start = cursor;
    consumeToken(tokenBlank);

    // Check the first non-blank character after the indent.
    if (currentChar() == null) {
      // EOF: A special character. End the Pattern.
      return null;
    }
    switch (currentChar()) {
      case ".":
      case "[":
      case "*":
      case "}":
        return null;
      case "{":
        // Placeables don't require indentation (in EBNF: block-placeable).
        // Continue the Pattern.
        return makeIndent(source.substring(start, cursor));
    }

    // If the first character on the line is not one of the special characters
    // listed above, it's a regular text character. Check if there's at least
    // one space of indent before it.
    if (source[cursor - 1] == " ") {
      // It's an indented text character (in EBNF: indented-char). Continue
      // the Pattern.
      return makeIndent(source.substring(start, cursor));
    }

    // A not-indented text character is likely the identifier of the next
    // message. End the Pattern.
    return null;
  }

  // Normalize a blank block and extract the indent details.
  Indent? makeIndent(String blank) {
    String value = blank.replaceAll(reBlankLines, "\n");
    int? length = reIndent.firstMatch(blank)?.group(1)?.length;
    return length == null ? null : Indent(value, length);
  }

  // Trim blanks in text according to the given regex.
  String trim(String text, RegExp re) {
    return text.replaceAll(re, "");
  }

  bool test(RegExp re) {
    return re.matchAsPrefix(source, cursor) != null;
  }

  Match match(RegExp re) {
    Match? result = re.matchAsPrefix(source, cursor);
    if (result == null) {
      throw SyntaxError("Expected $re");
    }
    cursor = result.end;
    return result;
  }

  String? match1(RegExp re) {
    return match(re).group(1);
  }

  // Advance the cursor by the char if it matches. May be used as a predicate
  // (was the match found?) or, if errorClass is passed, as an assertion.
  bool consumeChar(String char, [bool raiseError = false]) {
    if (currentChar() == char) {
      cursor++;
      return true;
    }
    if (raiseError) {
      throw SyntaxError("Expected $char");
    }
    return false;
  }

  // Advance the cursor by the token if it matches. May be used as a predicate
  // (was the match found?) or, if errorClass is passed, as an assertion.
  bool consumeToken(RegExp re, [bool raiseError = false]) {
    Match? result = re.matchAsPrefix(source, cursor);
    if (result != null) {
      cursor = result.end;
      return true;
    }
    if (raiseError) {
      throw SyntaxError("Expected $re");
    }
    return false;
  }

  String? currentChar() {
    if (cursor >= source.length) {
      return null;
    } else {
      return source[cursor];
    }
  }
}
