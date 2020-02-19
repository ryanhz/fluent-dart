import 'dart:core';
import 'dart:math';

import 'package:fluent/src/error.dart';

import './ast.dart';


class FluentParser {

	// This regex is used to iterate through the beginnings of messages and terms.
	// With the multiLine flag, the ^ matches at the beginning of every line.
	final RE_MESSAGE_START = RegExp(r"^(-?[a-zA-Z][\w-]*) *= *", caseSensitive: false, multiLine: true, dotAll: true);
	// Both Attributes and Variants are parsed in while loops. These regexes are
	// used to break out of them.
	final RE_ATTRIBUTE_START = RegExp(r"\.([a-zA-Z][\w-]*) *= *", caseSensitive: true, multiLine: false,);
	final RE_VARIANT_START = RegExp(r"\*?\[", caseSensitive: true, multiLine: false,);

	final RE_NUMBER_LITERAL = RegExp(r"(-?[0-9]+(?:\.([0-9]+))?)", caseSensitive: true, multiLine: false,);
	final RE_IDENTIFIER = RegExp(r"([a-zA-Z][\w-]*)", caseSensitive: true, multiLine: false,);
	final RE_REFERENCE = RegExp(r"([$-])?([a-zA-Z][\w-]*)(?:\.([a-zA-Z][\w-]*))?", caseSensitive: true, multiLine: false,);
	final RE_FUNCTION_NAME = RegExp(r"^[A-Z][A-Z0-9_-]*$", caseSensitive: true, multiLine: false,);

	// A "run" is a sequence of text or string literal characters which don't
	// require any special handling. For TextElements such special characters are: {
	// (starts a placeable), and line breaks which require additional logic to check
	// if the next line is indented. For StringLiterals they are: \ (starts an
	// escape sequence), " (ends the literal), and line breaks which are not allowed
	// in StringLiterals. Note that string runs may be empty; text runs may not.
	final RE_TEXT_RUN = RegExp(r"([^{}\n\r]+)", caseSensitive: false, multiLine: true,);
	final RE_STRING_RUN = RegExp(r'([^\\"\n\r]*)', caseSensitive: false, multiLine: true,);

	final RE_STRING_ESCAPE = RegExp(r'\\([\\"])', caseSensitive: false, multiLine: true,);
	final RE_UNICODE_ESCAPE = RegExp(r"\\u([a-fA-F0-9]{4})|\\U([a-fA-F0-9]{6})", caseSensitive: false, multiLine: true,);

	// Used for trimming TextElements and indents.
	final RE_LEADING_NEWLINES = RegExp(r'^\n+', caseSensitive: false, );
	final RE_TRAILING_SPACES = RegExp(r' +$', caseSensitive: false, );
	// Used in makeIndent to strip spaces from blank lines and normalize CRLF to LF.
	final RE_BLANK_LINES = RegExp(r' *\r?\n', caseSensitive: false, multiLine: true, dotAll: true);
	// Used in makeIndent to measure the indentation.
	final RE_INDENT = RegExp(r'( *)$', caseSensitive: false, multiLine: true,);

	// Common tokens.
	final TOKEN_BRACE_OPEN = RegExp(r'{\s*', caseSensitive: false, multiLine: false,);
	final TOKEN_BRACE_CLOSE = RegExp(r'\s*}', caseSensitive: false, multiLine: false,);
	final TOKEN_BRACKET_OPEN = RegExp(r'\[\s*', caseSensitive: false, multiLine: false,);
	final TOKEN_BRACKET_CLOSE = RegExp(r'\s*] *', caseSensitive: false, multiLine: false,);
	final TOKEN_PAREN_OPEN = RegExp(r'\s*\(\s*', caseSensitive: false, multiLine: false,);
	final TOKEN_ARROW = RegExp(r'\s*->\s*', caseSensitive: false, multiLine: false,);
	final TOKEN_COLON = RegExp(r'\s*:\s*', caseSensitive: false, multiLine: false,);
	// Note the optional comma. As a deviation from the Fluent EBNF, the parser
	// doesn't enforce commas between call arguments.
	final TOKEN_COMMA = RegExp(r'\s*,?\s*', caseSensitive: false, multiLine: true,);
	final TOKEN_BLANK = RegExp(r'\s+', caseSensitive: false, multiLine: true,);


	final String source;
	int cursor = 0;
	FluentParser(this.source);

	Resource parse() {
		// Iterate over the beginnings of messages and terms to efficiently skip
		// comments and recover from errors.
		Resource resource = Resource();
		for(RegExpMatch match in RE_MESSAGE_START.allMatches(source)) {
			String id = match.group(1);
			cursor = match.end;
			resource.body.add(parseMessage(id));
		}
		return resource;
	}

	Message parseMessage(String id) {
		final value = parsePattern();
		final attributes = parseAttributes();
		if(value==null || attributes.length==0) {
			throw SyntaxError("Expected message value or attributes");
		}
		return Message(id, value, attributes);
	}

	Map<String, Pattern> parseAttributes() {
		Map<String, Pattern> attrs = {};
		while(test(RE_ATTRIBUTE_START)) {
			String name = match1(RE_ATTRIBUTE_START);
			Pattern value = parsePattern();
			if (value == null) {
				throw SyntaxError("Expected attribute value");
			}
			attrs[name] = value;
		}
		return attrs;
	}

	Pattern parsePattern() {
		String first;
		// First try to parse any simple text on the same line as the id.
		if (test(RE_TEXT_RUN)) {
			first = match1(RE_TEXT_RUN);
		}

		// If there's a placeable on the first line, parse a complex pattern.
		if (source[cursor] == "{" || source[cursor] == "}") {
			// Re-use the text parsed above, if possible.
			return parsePatternElements(first!=null ? [TextElement(first)] : [], 65536);
		}
		// RE_TEXT_VALUE stops at newlines. Only continue parsing the pattern if
		// what comes after the newline is indented.
		Indent indent = parseIndent();
		if(indent!=null) {
			if(first!=null) {
				// If there's text on the first line, the blank block is part of the
				// translation content in its entirety.
				return parsePatternElements([TextElement(first), indent], indent.length);
			}
			// Otherwise, we're dealing with a block pattern, i.e. a pattern which
			// starts on a new line. Discrad the leading newlines but keep the
			// inline indent; it will be used by the dedentation logic.
			indent.value = trim(indent.value, RE_LEADING_NEWLINES);
			return parsePatternElements([indent], indent.length);
		}
		if(first!=null) {
			// It was just a simple inline text after all.
			return Pattern.from([TextElement(trim(first, RE_TRAILING_SPACES))]);
		}
		return null;
	}

	Pattern parsePatternElements(List<PatternElement> elements, int commonIndent) {
		while (true) {
			if (test(RE_TEXT_RUN)) {
				String text = match1(RE_TEXT_RUN);
				elements.add(TextElement(text));
				continue;
			}

			if (source[cursor] == "{") {
				elements.add(parsePlaceable());
				continue;
			}

			if (source[cursor] == "}") {
				throw SyntaxError("Unbalanced closing brace");
			}

			final indent = parseIndent();
			if (indent!=null) {
				elements.add(indent);
				commonIndent = min(commonIndent, indent.length);
				continue;
			}
			break;
		}

		final lastIndex = elements.length - 1;
		final lastElement = elements[lastIndex];
		// Trim the trailing spaces in the last element if it's a TextElement.
		if(lastElement is TextElement) {
			lastElement.value = trim(lastElement.value, RE_TRAILING_SPACES);
		}

		List<PatternElement> baked = [];
		for (var element in elements) {
			if(element is Indent) {
				// Dedent indented lines by the maximum common indent.
				element.value = element.value.substring(0, element.value.length - commonIndent);
				if(element.value.length>0) {
					baked.add(element);
				}
			}
			else {
				baked.add(element);
			}
		}
		return Pattern.from(baked);
	}

	Expression parsePlaceable() {
		consumeToken(TOKEN_BRACE_OPEN, true);

		final selector = parseInlineExpression();
		if (consumeToken(TOKEN_BRACE_CLOSE)) {
			return selector;
		}
		if (consumeToken(TOKEN_ARROW)) {
			List<Variant> variants = parseVariants();
			consumeToken(TOKEN_BRACE_CLOSE, true);
			return SelectExpression(selector, variants);
		}
		throw SyntaxError("Unclosed placeable");
	}

	Expression parseInlineExpression() {
		if (source[cursor] == "{") {
			// It's a nested placeable.
			return parsePlaceable();
		}

		if (test(RE_REFERENCE)) {
			Match m = match(RE_REFERENCE);
			String sigil = m.group(1);
			String name = m.group(2);
			String attr = m.group(3);
			if (sigil == "\$") {
				return VariableReference(name);
			}

			if (consumeToken(TOKEN_PAREN_OPEN)) {
				final args = parseArguments();

				if (sigil == "-") {
					// A parameterized term: -term(...).
					return TermReference(name, attr, args);
				}
				if (RE_FUNCTION_NAME.hasMatch(name)) {
					return FunctionReference(name, args);
				}

				throw SyntaxError("Function names must be all upper-case");
			}

			if (sigil == "-") {
				// A non-parameterized term: -term.
				return TermReference(name, attr);
			}

			return MessageReference(name, attr);
		}

		return parseLiteral();
	}

	List<Argument> parseArguments() {
		List<Argument> args = [];
		while (true) {
			if(cursor>=source.length) {
				throw SyntaxError("Unclosed argument list");
			}
			// End of the argument list.
			else if(source[cursor]==")") {
				cursor++;
				return args;
			}

			args.add(parseArgument());
			// Commas between arguments are treated as whitespace.
			consumeToken(TOKEN_COMMA);
		}
	}

	Argument parseArgument() {
		final expr = parseInlineExpression();
		if(expr is MessageReference) {
			if (consumeToken(TOKEN_COLON)) {
				// The reference is the beginning of a named argument.
				final value = parseLiteral();
				return NamedArgument(expr.id, value);
			}

			// It's a regular message reference.
			return PositionalArgument(expr);
		}
		else {
			return PositionalArgument(expr);
		}
	}

	List<Variant> parseVariants() {
		//TODO parse variants
		return [];
	}

	Literal parseLiteral() {
		if (test(RE_NUMBER_LITERAL)) {
			return parseNumberLiteral();
		}

		if (source[cursor] == '"') {
			return parseStringLiteral();
		}

		throw SyntaxError("Invalid expression");
	}

	NumberLiteral parseNumberLiteral() {
		Match m = match(RE_NUMBER_LITERAL);
		String value = m.group(1);
		String fraction = m.group(2) ?? "";
		int precision = fraction.length;
		return NumberLiteral(double.parse(value), precision);
	}

	StringLiteral parseStringLiteral() {
		consumeChar('"', true);
		StringBuffer sb = StringBuffer();
		while (true) {
			String value = match1(RE_STRING_RUN);
			sb.write(value);

			if(cursor>=source.length) {
				// We've reached an EOL of EOF.
				throw SyntaxError("Unclosed string literal");
			}
			if (source[cursor] == "\\") {
				sb.write(parseEscapeSequence());
				continue;
			}
			if (consumeChar('"')) {
				return StringLiteral(sb.toString());
			}
		}
	}

	String parseEscapeSequence() {
		if (test(RE_STRING_ESCAPE)) {
			return match1(RE_STRING_ESCAPE);
		}

		if (test(RE_UNICODE_ESCAPE)) {
			Match m = match(RE_UNICODE_ESCAPE);
			String codepoint4 = m.group(1);
			String codepoint6 = m.group(2);
			int codepoint = int.parse(codepoint4 ?? codepoint6, radix:16);
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
	Indent parseIndent() {
		int start = cursor;
		consumeToken(TOKEN_BLANK, false);

		// Check the first non-blank character after the indent.
		if(cursor>=source.length) {
			// EOF: A special character. End the Pattern.
			return null;
		}
		switch (source[cursor]) {
			case ".":
			case "[":
			case "*":
			case "}":
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
	Indent makeIndent(String blank) {
		String value = blank.replaceAll(RE_BLANK_LINES, "\n");
		int length = RE_INDENT.firstMatch(blank).group(1).length;
		return Indent(value, length);
	}

	// Trim blanks in text according to the given regex.
	String trim(String text, RegExp re) {
		return text.replaceAll(re, "");
	}

	bool test(RegExp re) {
		return re.matchAsPrefix(source, cursor)!=null;
	}

	Match match(RegExp re) {
		Match result = re.matchAsPrefix(source, cursor);
		if (result == null) {
			throw SyntaxError("Expected $re");
		}
		cursor = result.end;
		return result;
	}

	String match1(RegExp re) {
		return match(re).group(1);
	}

	// Advance the cursor by the char if it matches. May be used as a predicate
	// (was the match found?) or, if errorClass is passed, as an assertion.
	bool consumeChar(String char, [bool raiseError=false]) {
		if (source[cursor] == char) {
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
	bool consumeToken(RegExp re, [bool raiseError=false]) {
		Match result = re.matchAsPrefix(source, cursor);
		if (result!=null) {
			cursor = result.end;
			return true;
		}
		if (raiseError) {
			throw SyntaxError("Expected $re");
		}
		return false;
	}

}
