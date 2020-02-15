
class FtlString implements FtlJunk, FtlIdentifier, FtlStringLiteral, FtlText, FtlCommentLine, FtlBlankBlock {
  final String content;

  FtlString._(this.content) : assert(content != null);

  static FtlString fromString(String content) {
    assert(content != null);
    return FtlString._(content);
  }
}

class FtlText implements _FtlPatternElementCandidate {}
class FtlJunk implements FtlResourceCandidate {}
class FtlBlankBlock implements FtlResourceCandidate {}
class FtlCommentLine {}

class FtlIdentifier implements _FtlVariantKeyCandidate {}

class FtlStringLiteral implements _FtlInlineExpressionCandidate {}

class FtlNumberLiteral extends FtlString implements _FtlInlineExpressionCandidate, _FtlVariantKeyCandidate {
  final num value;

  FtlNumberLiteral(String content)
      : this.value = num.parse(content),
        super._(content);
}

class FtlAttribute {
  final FtlIdentifier identifier;
  final FtlPattern pattern;

  FtlAttribute({this.identifier, this.pattern});
}

class FtlAttributeAccessor {
  final FtlIdentifier identifier;

  FtlAttributeAccessor({this.identifier});
}

class FtlNamedArgument implements _FtlArgumentCandidate {
  final FtlIdentifier identifier;

  // Either FtlNumberLiteral or FtlStringLiteral.
  final dynamic literal;

  FtlNamedArgument(this.identifier, this.literal)
      : assert(identifier != null),
        assert(literal is FtlNumberLiteral || literal is FtlStringLiteral);
}

class _FtlArgumentCandidate {}

class FtlArgument {
  final _FtlArgumentCandidate argument;

  FtlArgument({this.argument});
}

class _FtlVariantKeyCandidate {}
class FtlVariantKey {
  final _FtlVariantKeyCandidate key;

  FtlVariantKey({this.key});
}

class FtlVariant {
  final FtlVariantKey variantKey;
  final FtlPattern pattern;

  FtlVariant({this.variantKey, this.pattern});
}

class FtlDefaultVariant {
  final FtlVariantKey variantKey;
  final FtlPattern pattern;

  FtlDefaultVariant({this.variantKey, this.pattern});
}


class FtlVariantList {
  final FtlDefaultVariant defaultVariant;
  final List<FtlVariant> variants;

  FtlVariantList({this.defaultVariant, this.variants});
}

class _FtlInlinePlaceableCandidate {}

class FtlInlinePlaceable implements _FtlPatternElementCandidate, _FtlInlineExpressionCandidate {
  final _FtlInlinePlaceableCandidate placeable;

  FtlInlinePlaceable({this.placeable});
}

class FtlBlockPlaceable implements _FtlInlinePlaceableCandidate {}

class _FtlInlineExpressionCandidate {}

class FtlInlineExpression implements _FtlInlinePlaceableCandidate, _FtlArgumentCandidate {
  final _FtlInlineExpressionCandidate expression;

  FtlInlineExpression({this.expression});
}

class _FtlPatternElementCandidate {}

class FtlPatternElement {
  final _FtlPatternElementCandidate element;

  FtlPatternElement({this.element});
}

class FtlPattern {
  final List<FtlPatternElement> patternElements;

  FtlPattern({this.patternElements});
}

class FtlSelectExpression implements _FtlInlinePlaceableCandidate {
  FtlInlineExpression inlineExpression;
  FtlVariantList variantList;

  FtlSelectExpression({FtlInlineExpression this.inlineExpression, FtlVariantList this.variantList});
}

class FtlArgumentList {
  final List<FtlArgument> arguments;

  FtlArgumentList({this.arguments});
}

class FtlCallArguments {
  final FtlArgumentList arguments;

  FtlCallArguments({this.arguments});
}

class FtlTermReference implements _FtlInlineExpressionCandidate {
  final FtlIdentifier identifier;
  final FtlAttributeAccessor attributeAccessor;
  final FtlCallArguments callArguments;

  FtlTermReference({this.identifier, this.attributeAccessor, this.callArguments});
}

class FtlMessageReference implements _FtlInlineExpressionCandidate {
  final FtlIdentifier identifier;
  final FtlAttributeAccessor attributeAccessor;

  FtlMessageReference({this.identifier, this.attributeAccessor});
}

class FtlFunctionReference implements _FtlInlineExpressionCandidate {
  final FtlIdentifier identifier;
  final FtlCallArguments callArguments;

  FtlFunctionReference({this.identifier, this.callArguments});
}

class FtlVariableReference implements _FtlInlineExpressionCandidate {
  final FtlIdentifier identifier;

  FtlVariableReference({this.identifier});
}

class FtlTerm {
  final FtlIdentifier identifier;
  final FtlPattern pattern;
  final List<FtlAttribute> attributes;

  FtlTerm({this.identifier, this.pattern, this.attributes});
}

class FtlMessage {
  final FtlIdentifier identifier;
  final FtlPattern pattern;
  final List<FtlAttribute> attributes;

  FtlMessage({this.identifier, this.pattern, this.attributes});
}

class FtlEntry implements FtlResourceCandidate {
  final FtlMessage message;
  final FtlTerm term;
  final FtlCommentLine commentLine;

  FtlEntry({this.message, this.term, this.commentLine});

  factory FtlEntry.forMessage(FtlMessage message) => FtlEntry(message: message);
  factory FtlEntry.forTerm(FtlTerm term) => FtlEntry(term: term);
  factory FtlEntry.forCommentLine(FtlCommentLine commentLine) => FtlEntry(commentLine: commentLine);
}

class FtlResourceCandidate {}

class FtlResource {
  final List<FtlResourceCandidate> resourceParts;

  FtlResource({this.resourceParts});
}