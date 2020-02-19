class Resource extends ASTNode {
	final List<Entry> body = [];
	Resource();
}

abstract class Entry extends ASTNode {}

class Comment extends Entry {
	final String content;
	Comment(this.content);
}

class GroupComment extends Comment {
	GroupComment(String content): super(content);
}

class ResourceComment extends Comment {
	ResourceComment(String content): super(content);
}

class Junk extends Entry {
	final String content;
	Junk(this.content);
}

class Message extends Entry {
	final String id;
	final Pattern value;
	final Map<String, Pattern> attributes;
	Message(this.id, this.value, [this.attributes=const {}]);
}

class Term extends Entry {
	final String id;
	final Pattern value;
	final Map<String, Pattern> attributes;
	Term(this.id, this.value, [this.attributes=const {}]);
}

class Pattern extends ASTNode {
	List<PatternElement> elements = [];
	Pattern();
	Pattern.from(this.elements);
}

abstract class PatternElement extends ASTNode {
	PatternElement();
}

class Indent extends PatternElement{
	String value;
	int length;
	Indent(this.value, this.length);
}

class TextElement extends PatternElement {
	String value;
	TextElement(this.value);
}

class Expression extends PatternElement {
}

class VariableReference extends Expression {
	final String id;
	VariableReference(this.id);
}

class TermReference extends Expression {
	final String id;
	final String attribute;
	final List<Argument> arguments;
	TermReference(this.id, this.attribute, [this.arguments = const []]);
}

class MessageReference extends Expression {
	final String id;
	final String attribute;
	MessageReference(this.id, this.attribute);
}

abstract class Literal extends Expression {
	Literal();
}

class StringLiteral extends Literal {
	final String value;
	StringLiteral(this.value);
}

class NumberLiteral extends Literal {
	final double value;
	final int precision;
	NumberLiteral(this.value, this.precision);
}

class FunctionReference extends Expression {
	final String id;
	final List<Argument> arguments;
	FunctionReference(this.id, [this.arguments = const []]);
}

abstract class Argument extends ASTNode {
}

class PositionalArgument extends Argument {
	final Expression expression;
	PositionalArgument(this.expression);
}

class NamedArgument extends Argument {
	final String name;
	final Literal value;
	NamedArgument(this.name, this.value);
}

class SelectExpression extends Expression {
	final Expression selector;
	final List<Variant> variants;
	SelectExpression(this.selector, this.variants);
}

class Variant extends ASTNode {
	final Literal key;
	final Pattern value;
	final bool isDefault;
	Variant(this.key, this.value, this.isDefault);
}

abstract class ASTNode {}
