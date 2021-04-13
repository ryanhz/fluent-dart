library fluent;

import 'ast.dart';
import 'builtin.dart';
import 'parser.dart';
import 'resolver.dart';
import 'scope.dart';
import 'types.dart';

typedef String TextTransform(String text);
String identity(String s) => s;

/// Message bundles are single-language stores of translation resources. They are
/// responsible for formatting message values and attributes to strings.
class FluentBundle {
  final String locale;
  final bool useIsolating;
  final TextTransform transform;

  final Map<String, Message> messages = {};
  final Map<String, Function> functions = {
    'NUMBER': NUMBER,
    'DATETIME': DATETIME,
  };

  FluentBundle(this.locale, {this.useIsolating = false, this.transform = identity});

  void addMessages(String source) {
    FluentParser parser = FluentParser(source);
    Resource resource = parser.parse();
    for (Message message in resource.body) {
      messages[message.id] = message;
    }
  }

  // Check if a message is present in the bundle.
  bool hasMessage(String id) {
    return this.messages.containsKey(id);
  }

  String format(String id, {Map<String, dynamic> args = const {}, List<Error>? errors, String? attribute}) {
    Message? message = this.messages[id];
    if (message == null) {
      return id;
    }
    Pattern? pattern = attribute == null ? message.value : message.attributes[attribute];
    if (pattern == null) {
      return id;
    }
    // Resolve a simple pattern without creating a scope. No error handling is
    // required; by definition simple patterns don't have placeables.
    if (pattern.elements.length == 1) {
      PatternElement element = pattern.elements.first;
      if (element is TextElement) {
        return this.transform(element.value);
      }
    }
    // Resolve a complex pattern.
    final scope = Scope(this, errors, args);
    try {
      FluentValue value = resolvePattern(scope, pattern);
      return value.toString();
    } on Error catch (err) {
      if (errors != null) {
        errors.add(err);
        return id;
      }
      throw err;
    }
  }
}
