library fluent;

import 'ast.dart';
import 'error.dart';
import 'parser.dart';
import 'types.dart';
import 'builtin.dart';
import 'scope.dart';
import 'resolver.dart';

typedef String TextTransform(String text);
String identity(String s) => s;

/// Message bundles are single-language stores of translation resources. They are
/// responsible for formatting message values and attributes to strings.
class FluentBundle {
  final String locale;
  final bool useIsolating;
  final TextTransform transform;

  final Map<String, Message> messages = {};
  // Identifiers starting with a dash (-) define terms. Terms are private and
  // cannot be retrieved from FluentBundle.
  final Map<String, Message> terms = {};
  Map<String, Function> get functions => {
        'NUMBER': NUMBER,
        'DATETIME': DATETIME,
      };

  FluentBundle(this.locale,
      {this.useIsolating = false, this.transform = identity});

  // Add a translation resource to the bundle. Returns the list of errors
  // encountered, e.g. attempts to override an existing message or term.
  // Overrides are allowed by default, to support merging resources from
  // different sources (e.g. base translations plus per-tenant overrides).
  // Pass allowOverrides: false to reject and report duplicate definitions.
  List<Error> addMessages(String source, {bool allowOverrides = true}) {
    List<Error> errors = [];
    FluentParser parser = FluentParser(source);
    Resource resource = parser.parse();
    for (Message message in resource.body) {
      if (message.id.startsWith('-')) {
        if (!allowOverrides && terms.containsKey(message.id)) {
          errors.add(ReferenceError(
              'Attempt to override an existing term: "${message.id}"'));
          continue;
        }
        terms[message.id] = message;
      } else {
        if (!allowOverrides && messages.containsKey(message.id)) {
          errors.add(ReferenceError(
              'Attempt to override an existing message: "${message.id}"'));
          continue;
        }
        messages[message.id] = message;
      }
    }
    return errors;
  }

  // Check if a message is present in the bundle.
  bool hasMessage(String id) {
    return this.messages.containsKey(id);
  }

  String? format(String id,
      {Map<String, dynamic> args = const {}, List<Error>? errors, String? attribute}) {
    Message? message = this.messages[id];
    if (message == null) {
      return null;
    }
    Pattern? pattern = attribute == null ? message.value : message.attributes[attribute];
    if (pattern == null) {
      return null;
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
    final scope = Scope(this, args, errors);
    try {
      FluentValue value = resolvePattern(scope, pattern);
      return value.toString();
    } on Error catch (err) {
      if (errors != null) {
        errors.add(err);
        return null;
      }
      throw err;
    }
  }
}
