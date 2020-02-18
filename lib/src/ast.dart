class Resource extends ASTNode {
	final List<Entry> body;
	Resource(Span span, this.body): super(span);
}

abstract class Entry extends ASTNode {
	Entry(Span span) : super(span);
}

class Comment extends Entry {
	final String content;
	Comment(Span span, this.content) : super(span);
}

class GroupComment extends Comment {
	GroupComment(Span span, String content): super(span, content);
}

class ResourceComment extends Comment {
	ResourceComment(Span span, String content): super(span, content);
}

class Junk extends Entry {
	final String content;
	Junk(Span span, this.content) : super(span);
}

class Message extends Entry {
	final Identifier id;
	final Pattern value;
	final List<Attribute> attributes;
	final Comment comment;
	Message(Span span, this.id, this.value, [this.attributes=const [], this.comment=null]): super(span);
}

class Term extends Entry {
	final Identifier id;
	final Pattern value;
	final List<Attribute> attributes;
	final Comment comment;
	Term(Span span, this.id, this.value, [this.attributes=const [], this.comment=null]): super(span);
}

class Identifier extends ASTNode {
	final String name;
	Identifier(Span span, this.name): super(span);
}

class Pattern extends ASTNode {
	final List<PatternElement> elements;
	Pattern(Span span, this.elements): super(span);
}

class Attribute extends ASTNode {
	final Identifier id;
	final Pattern value;
	Attribute(Span span, this.id, this.value): super(span);
}

abstract class PatternElement extends ASTNode {
	PatternElement(Span span): super(span);
}

class TextElement extends PatternElement {
	final String value;
	TextElement(Span span, this.value): super(span);
}

class Placeable extends PatternElement {
	final Expression expression;
	Placeable(Span span, this.expression): super(span);
}

abstract class Expression extends ASTNode {
	Expression(Span span): super(span);
}

class VariableReference extends Expression {
	final Identifier id;
	VariableReference(Span span, this.id): super(span);
}

class TermReference extends Expression {
	final Identifier id;
	final Attribute attribute;
	final CallArguments arguments;
	TermReference(Span span, this.id, this.attribute, this.arguments): super(span);
}

class MessageReference extends Expression {
	final Identifier id;
	final Attribute attribute;
	MessageReference(Span span, this.id, this.attribute): super(span);
}

abstract class Literal extends Expression {
	Literal(Span span): super(span);
}

class StringLiteral extends Literal {
	final String value;
	StringLiteral(Span span, this.value): super(span);
}

class NumberLiteral extends Literal {
	final String value;
	NumberLiteral(Span span, this.value): super(span);
}

class FunctionReference extends Expression {
	final Identifier id;
	final CallArguments arguments;
	FunctionReference(Span span, this.id, this.arguments): super(span);
}

class CallArguments extends ASTNode {
	final List<VariableReference> positional;
	final List<NamedArgument> named;
	CallArguments(Span span, [this.positional = const [], this.named = const []]): super(span);
}

class NamedArgument extends ASTNode {
	final Identifier name;
	final Literal value;
	NamedArgument(Span span, this.name, this.value): super(span);
}

class SelectExpression extends Expression {
	final Expression selector;
	final List<Variant> variants;
	SelectExpression(Span span, this.selector, this.variants): super(span);
}

class Variant extends ASTNode {
	final Literal key;
	final Pattern value;
	final bool isDefault;
	Variant(Span span, this.key, this.value, this.isDefault): super(span);
}

abstract class ASTNode {
	final Span span;
	ASTNode(this.span);
}

class Span {
	final int start;
	final int end;
	Span(this.start, this.end);
}
