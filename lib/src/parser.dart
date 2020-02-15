import './ast.dart';
import 'package:petitparser/petitparser.dart';

Parser _setUpParser() {
  Parser<FtlString> _line_end = (string('\u000D\u000A') | string('\u000A')).flatten().map(FtlString.fromString);
  Parser<FtlString> _blank_inline = char('\u0020').plus().flatten().map(FtlString.fromString);
  Parser<FtlBlankBlock> _blank_block = (_blank_inline & _line_end).plus().flatten().map(FtlString.fromString);
  Parser<FtlString> _blank = (_blank_inline | _line_end).plus().flatten().map(FtlString.fromString);

  Parser<FtlString> _junk_line = (_line_end.neg().star() & _line_end).flatten().map(FtlString.fromString);
  Parser<FtlJunk> _junk = (_junk_line & ((letter() | char('#') | char('-')).not() & _junk_line).star()).flatten().map(FtlString.fromString);

  Parser<FtlString> _special_text_char = (char('{') | char('}')).flatten().map(FtlString.fromString);
  Parser<FtlString> _text_char = ((_special_text_char.or(_line_end)).not() & any()).flatten().map(FtlString.fromString);
  Parser<FtlString> _indented_char = ((char('.').or(char('*')).or(char('['))).not() & _text_char).flatten().map(FtlString.fromString);
  Parser<FtlString> _special_quoted_char = (char('"') | char('\\')).flatten().map(FtlString.fromString);
  Parser<FtlString> _special_escape = (char('\\') & _special_quoted_char).flatten().map(FtlString.fromString);
  Parser<FtlString> _unicode_escape_4 = (string('\\u') & word().times(4)).flatten().map(FtlString.fromString);
  Parser<FtlString> _unicode_escape_6 = (string('\\U') & word().times(6)).flatten().map(FtlString.fromString);
  Parser<FtlString> _unicode_escape = (_unicode_escape_4 | _unicode_escape_6).map((dynamic raw) => raw);
  Parser<FtlString> _quoted_char = (_text_char | _special_escape | _unicode_escape).map((dynamic raw) => raw);

  Parser<FtlText> _inline_text = _text_char.plus().flatten().map(FtlString.fromString);
  Parser<FtlText> _block_text = (_blank_block & _blank_inline & _indented_char & _inline_text.optional()).flatten().map(FtlString.fromString);

  Parser<FtlString> _comment_char = (_line_end.not() & any()).flatten().map(FtlString.fromString);
  Parser<FtlCommentLine> _comment_line = ((string('###') | string('##') | string('#')) & (char(' ') & _comment_char.star()).optional([]) & _line_end).flatten().map(FtlString.fromString);

  Parser<FtlIdentifier> _identifier = (letter() & (word() | char('_') | char('-')).star()).flatten().map(FtlString.fromString);
  Parser<FtlNumberLiteral> _number_literal = ((char('-').optional('')) & digit().plus() & (char('.') & digit().plus()).optional([''])).flatten().map((String content) => FtlNumberLiteral(content));
  Parser<FtlStringLiteral> _string_literal = (char('"') & _quoted_char.star() & char('"')).pick<String>(1).map(FtlString.fromString);

  SettableParser<FtlSelectExpression> _select_expression = undefined();
  SettableParser<FtlInlineExpression> _inline_expression = undefined();

  Parser<FtlInlinePlaceable> _inline_placeable =
      (char('{') & _blank.optional() & (_select_expression | _inline_expression) & _blank.optional() & char('}')).pick(2).map((raw) => FtlInlinePlaceable(placeable: raw));
  Parser<FtlBlockPlaceable> _block_placeable = (_blank_block & _blank_inline.optional() & _inline_placeable).pick(2);

  Parser<FtlPatternElement> _pattern_element = (_inline_text | _block_text | _inline_placeable | _block_placeable).map((raw) => FtlPatternElement(element: raw));
  Parser<FtlPattern> _pattern = _pattern_element.plus().map((List<FtlPatternElement> elements) => FtlPattern(patternElements: elements));
  Parser<FtlAttribute> _attribute = (_line_end & _blank.optional() & char('.') & _identifier & _blank_inline.optional() & char('=') & _blank_inline.optional() & _pattern)
      .map((List<dynamic> raw) => FtlAttribute(identifier: raw[3], pattern: raw[7]));

  Parser<FtlNamedArgument> _named_argument =
      (_identifier & (_blank.optional() & char(':') & _blank.optional()).flatten() & (_string_literal | _number_literal)).map((List<dynamic> parts) => FtlNamedArgument(parts[0], parts[2]));
  Parser<FtlArgument> _argument = (_named_argument | _inline_expression).map((raw) => FtlArgument(argument: raw));
  Parser<FtlArgumentList> _argument_list = ((_argument & _blank.optional() & char(',') & _blank.optional()).pick(0).star() & _argument.optional())
      .map((List raw) => FtlArgumentList(arguments: List.from([raw[0], raw[1]].where((dynamic element) => element != null))));

  Parser<FtlCallArguments> _call_arguments = (char('(').trim(_blank, _blank) & _argument_list & char(')').trim(_blank)).pick(1).map((dynamic args) => FtlCallArguments(arguments: args));
  Parser<FtlAttributeAccessor> _attribute_accessor = (char('.') & _identifier).pick(1).map((raw) => FtlAttributeAccessor(identifier: raw));
  Parser<FtlTermReference> _term_reference = (char('-') & _identifier & _attribute_accessor.optional() & _call_arguments.optional())
      .map((List<dynamic> raw) => FtlTermReference(identifier: raw[1], attributeAccessor: raw[2], callArguments: raw[3]));
  Parser<FtlMessageReference> _message_reference = (_identifier & _attribute_accessor.optional()).map((List<dynamic> raw) => FtlMessageReference(identifier: raw[0], attributeAccessor: raw[1]));
  Parser<FtlFunctionReference> _function_reference = (_identifier & _call_arguments).map((List<dynamic> raw) => FtlFunctionReference(identifier: raw[0], callArguments: raw[1]));
  Parser<FtlVariableReference> _variable_reference = (char('\$') & _identifier).pick(1).map((dynamic identifier) => FtlVariableReference(identifier: identifier));

  Parser<FtlVariantKey> _variant_key = (char('[') & _blank.optional() & (_number_literal | _identifier) & _blank.optional() & char(']')).pick(3).map((dynamic key) => FtlVariantKey(key: key));
  Parser<FtlDefaultVariant> _default_variant =
      (_line_end & _blank.optional() & char('*') & _variant_key & _blank_inline.optional() & _pattern).map((List<dynamic> raw) => FtlDefaultVariant(variantKey: raw[3], pattern: raw[5]));
  Parser<FtlVariant> _variant = (_line_end & _blank.optional() & _variant_key & _blank_inline.optional() & _pattern).map((List<dynamic> raw) => FtlVariant(variantKey: raw[2], pattern: raw[4]));
  Parser<FtlVariantList> _variant_list = (_variant.star() & _default_variant & _variant.star() & _line_end).map((List<dynamic> raw) => FtlVariantList(defaultVariant: raw[1], variants: raw[2]));
  ;

  Parser<FtlTerm> _term =
      (char('-') & _identifier & char('=').trim(_blank, _blank) & _pattern & _attribute.star()).map((List<dynamic> raw) => FtlTerm(identifier: raw[1], pattern: raw[3], attributes: raw[4]));
  ;
  Parser<FtlMessage> _message = (_identifier & char('=').trim(_blank_inline, _blank_inline) & ((_pattern & _attribute.star()) | _attribute.plus())).map((List<dynamic> raw) {
    assert(raw[2] is List && raw[2].isNotEmpty);
    if (raw[2][0] is FtlPattern) {
      return FtlMessage(identifier: raw[0], pattern: raw[2][0], attributes: List.castFrom((raw[2]).sublist(1)));
    } else {
      return FtlMessage(identifier: raw[0], attributes: raw[2] as List<FtlAttribute>);
    }
  });
  Parser<FtlEntry> _entry = ((_message & _line_end).pick(0) | (_term & _line_end).pick(0) | _comment_line).map((raw) {
    if (raw is FtlMessage) return FtlEntry.forMessage(raw);
    if (raw is FtlTerm) return FtlEntry.forTerm(raw);
    if (raw is FtlCommentLine) return FtlEntry.forCommentLine(raw);
    assert(false);
    return null;
  });

  _select_expression.set((_inline_expression & (_blank.optional() & string('->') & _blank_inline.optional()).flatten() & _variant_list)
      .map((List<dynamic> raw) => FtlSelectExpression(inlineExpression: raw[0], variantList: raw[2])));
  _inline_expression.set(
      (_string_literal | _number_literal | _function_reference | _message_reference | _term_reference | _variable_reference | _inline_placeable).map((raw) => FtlInlineExpression(expression: raw)));

  Parser<FtlResource> _resource = (_entry | _blank_block | _junk).star().map((List<dynamic> raw) => FtlResource(resourceParts: List.castFrom(raw)));
  return _resource;
}

Parser<FtlResource> _resourceParser = _setUpParser();

Result<FtlResource> parseFtl(String input) => _resourceParser.parse(input);