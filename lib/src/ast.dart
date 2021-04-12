class Resource {
  final List<Message> body = [];
  Resource();
}

class Message {
  final String id;
  final Pattern value;
  final Map<String, Pattern> attributes;
  Message(this.id, this.value, [this.attributes = const {}]);
}

class Pattern {
  List<PatternElement> elements = [];
  Pattern(this.elements);
}

abstract class PatternElement {
  PatternElement();
}

class Indent extends PatternElement {
  String value;
  int length;
  Indent(this.value, this.length);
}

class TextElement extends PatternElement {
  String value;
  TextElement(this.value);
}

class Expression extends PatternElement {}

class VariableReference extends Expression {
  final String? name;
  VariableReference(this.name);
}

class TermReference extends Expression {
  final String name;
  final String? attr;
  final List<Argument> arguments;
  TermReference(this.name, this.attr, [this.arguments = const []]);
}

class MessageReference extends Expression {
  final String name;
  final String? attr;
  MessageReference(this.name, this.attr);
}

abstract class Literal extends Expression {
  Literal();
}

class StringLiteral extends Literal {
  final String value;
  StringLiteral(this.value);
}

class NumberLiteral extends Literal {
  final num value;
  final int precision;
  NumberLiteral(this.value, this.precision);
}

class FunctionReference extends Expression {
  final String name;
  final List<Argument> arguments;
  FunctionReference(this.name, [this.arguments = const []]);
}

abstract class Argument {}

class PositionalArgument extends Argument {
  final Expression value;
  PositionalArgument(this.value);
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

class Variant {
  final Literal key;
  final Pattern value;
  final bool isDefault;
  Variant(this.key, this.value, this.isDefault);
}
