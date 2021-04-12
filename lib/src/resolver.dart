import 'package:intl/intl.dart';
import 'package:intl/src/plural_rules.dart' as plural_rules;

import 'ast.dart';
import 'error.dart';
import 'scope.dart';
import 'types.dart';

// The maximum number of placeables which can be expanded in a single call to
// `formatPattern`. The limit protects against the Billion Laughs and Quadratic
// Blowup attacks. See https://msdn.microsoft.com/en-us/magazine/ee335713.aspx.
const MAX_PLACEABLES = 100;

// Unicode bidi isolation characters.
const FSI = "\u2068";
const PDI = "\u2069";

// Resolve a pattern (a complex string with placeables).
FluentValue resolvePattern(Scope scope, Pattern pattern) {
  if (scope.dirty.contains(pattern)) {
    scope.reportError(new RangeError("Cyclic reference"));
    return FluentNone();
  }

  // Tag the pattern as dirty for the purpose of the current resolution.
  scope.dirty.add(pattern);
  List<FluentValue> result = [];

  // Wrap interpolations with Directional Isolate Formatting characters
  // only when the pattern has more than one element.
  bool useIsolating = scope.bundle.useIsolating && pattern.elements.length > 1;

  for (var element in pattern.elements) {
    if (element is TextElement) {
      result.add(FluentString(scope.bundle.transform(element.value)));
      continue;
    }
    if (element is Indent) {
      result.add(FluentString(scope.bundle.transform(element.value)));
      continue;
    }

    scope.placeables++;
    if (scope.placeables > MAX_PLACEABLES) {
      scope.dirty.remove(pattern);
      // This is a fatal error which causes the resolver to instantly bail out
      // on this pattern. The length check protects against excessive memory
      // usage, and throwing protects against eating up the CPU when long
      // placeables are deeply nested.
      throw RangeError("Too many placeables expanded: ${scope.placeables}, max allowed is $MAX_PLACEABLES");
    }

    if (useIsolating) {
      result.add(FluentString(FSI));
    }
    result.add(resolveExpression(scope, element as Expression));

    if (useIsolating) {
      result.add(FluentString(PDI));
    }
  }

  scope.dirty.remove(pattern);
  return FluentString(result.join());
}

// Resolve an expression to a Fluent type.
FluentValue resolveExpression(Scope scope, Expression expr) {
  if (expr is StringLiteral) {
    return FluentString(expr.value);
  } else if (expr is NumberLiteral) {
    return FluentNumber(expr.value, locale: scope.bundle.locale, minimumFractionDigits: expr.precision);
  } else if (expr is VariableReference) {
    return resolveVariableReference(scope, expr);
  } else if (expr is MessageReference) {
    return resolveMessageReference(scope, expr);
  } else if (expr is TermReference) {
    return resolveTermReference(scope, expr);
  } else if (expr is FunctionReference) {
    return resolveFunctionReference(scope, expr);
  } else if (expr is SelectExpression) {
    return resolveSelectExpression(scope, expr);
  } else {
    return FluentNone();
  }
}

// Resolve a reference to a variable.
FluentValue resolveVariableReference(Scope scope, VariableReference reference) {
  var arg;
  final params = scope.params;
  if (params != null) {
    // We're inside a TermReference. It's OK to reference undefined parameters.
    if (params.containsKey(reference.name)) {
      arg = params[reference.name];
    } else {
      return FluentNone("\$${reference.name}");
    }
  } else if (scope.args.containsKey(reference.name)) {
    // We're in the top-level Pattern or inside a MessageReference. Missing
    // variables references produce ReferenceErrors.
    arg = scope.args[reference.name];
  } else {
    scope.reportError(ReferenceError("Unknown variable: ${reference.name}"));
    return FluentNone("\$${reference.name}");
  }

  // Return early if the argument already is an instance of FluentValue.
  if (arg is FluentValue) {
    return arg;
  }

  if (arg is String) {
    return FluentString(arg);
  } else if (arg is num) {
    return FluentNumber(
      arg,
      locale: scope.bundle.locale,
    );
  } else if (arg is DateTime) {
    return FluentDateTime(arg, locale: scope.bundle.locale);
  } else {
    scope.reportError(UnsupportedError("Variable type not supported: ${reference.name}, ${arg.runtimeType}"));
    return FluentNone("\$${reference.name}");
  }
}

// Resolve a reference to another message.
FluentValue resolveMessageReference(Scope scope, MessageReference reference) {
  String name = reference.name;
  String? attr = reference.attr;
  final message = scope.bundle.messages[name];
  if (message == null) {
    scope.reportError(ReferenceError("Unknown message: $name"));
    return FluentNone(name);
  }
  if (attr != null) {
    final attribute = message.attributes[attr];
    if (attribute != null) {
      return resolvePattern(scope, attribute);
    }
    scope.reportError(ReferenceError("Unknown attribute: $attr"));
    return FluentNone("$name.$attr");
  }
  var pattern = message.value;
  if (pattern != null) {
    return resolvePattern(scope, pattern);
  }

  scope.reportError(ReferenceError("No value: $name"));
  return FluentNone(name);
}

// Resolve a call to a Term with key-value arguments.
FluentValue resolveTermReference(Scope scope, TermReference reference) {
  String name = reference.name;
  String? attr = reference.attr;
  List<Argument> args = reference.arguments;
  final term = scope.bundle.messages[name];
  if (term == null) {
    scope.reportError(ReferenceError("Unknown term: $name"));
    return FluentNone(name);
  }
  if (attr != null) {
    final attribute = term.attributes[attr];
    if (attribute != null) {
      // Every TermReference has its own variables.
      scope.params = getArguments(scope, args).named;
      final resolved = resolvePattern(scope, attribute);
      scope.params = null;
      return resolved;
    }
    scope.reportError(ReferenceError("Unknown attribute: $attr"));
    return FluentNone("$name.$attr");
  }

  scope.params = getArguments(scope, args).named;
  var pattern = term.value;
  if (pattern == null) {
    scope.reportError(ReferenceError("No pattern"));
    return FluentNone("$name");
  }
  final resolved = resolvePattern(scope, pattern);
  scope.params = null;
  return resolved;
}

// Resolve a call to a Function with positional and key-value arguments.
FluentValue resolveFunctionReference(Scope scope, FunctionReference reference) {
  String name = reference.name;
  var args = reference.arguments;
  var func = scope.bundle.functions[name];
  if (func == null) {
    scope.reportError(ReferenceError("Unknown function: $name()"));
    return FluentNone("$name()");
  }

  if (!(func is Function)) {
    scope.reportError(AssertionError("Function $name() is not callable"));
    return FluentNone("$name()");
  }

  try {
    final resolved = getArguments(scope, args);
    return Function.apply(func, resolved.positional, resolved.named);
  } on Error catch (err) {
    scope.reportError(err);
    return FluentNone("$name()");
  }
}

// Resolve a select expression to the member object.
FluentValue resolveSelectExpression(Scope scope, SelectExpression select) {
  final selector = select.selector;
  final variants = select.variants;
  final sel = resolveExpression(scope, selector);
  if (sel is FluentNone) {
    return getDefault(scope, variants);
  }

  // Match the selector against keys of each variant, in order.
  for (var variant in variants) {
    final key = resolveExpression(scope, variant.key);
    if (match(scope, sel, key)) {
      return resolvePattern(scope, variant.value);
    }
  }

  return getDefault(scope, variants);
}

// Helper: resolve arguments to a call expression.
Arguments getArguments(Scope scope, List<Argument> args) {
  List<dynamic> positional = [];
  Map<Symbol, dynamic> named = {};
  for (Argument arg in args) {
    if (arg is PositionalArgument) {
      positional.add(resolveExpression(scope, arg.value).value);
    } else if (arg is NamedArgument) {
      Symbol symbol = Symbol(arg.name);
      FluentValue expr = resolveExpression(scope, arg.value);
      if (expr is FluentNumber) {
        if (expr.value is double) {
          expr.value = expr.value.round();
        }
      }
      named[symbol] = expr.value;
    }
  }
  return Arguments(positional, named);
}

// Helper: match a variant key to the given selector.
bool match(Scope scope, FluentValue selector, FluentValue key) {
  if (key == selector) {
    // Both are strings.
    return true;
  }
  // XXX Consider comparing options too, e.g. minimumFractionDigits.
  if (key is FluentNumber && selector is FluentNumber && key.value == selector.value) {
    return true;
  }

  if (key is FluentString && selector is FluentString && key.value == selector.value) {
    return true;
  }

  if (selector is FluentNumber && key is FluentString) {
    plural_rules.PluralRule? pluralRule = _pluralRule(scope.bundle.locale, selector.value);
    plural_rules.PluralCase pluralCase = pluralRule!(); //null-safety !
    String category = pluralCase.toString().split('.').last.toLowerCase();
    if (key.value.toLowerCase() == category) {
      return true;
    }
  }
  return false;
}

// Helper: resolve the default variant from a list of variants.
FluentValue getDefault(Scope scope, List<Variant> variants) {
  for (Variant variant in variants) {
    if (variant.isDefault) {
      return resolvePattern(scope, variant.value);
    }
  }

  scope.reportError(RangeError("No default"));
  return FluentNone();
}

plural_rules.PluralRule? _cachedPluralRule;
String? _cachedPluralLocale;

plural_rules.PluralRule? _pluralRule(String locale, num howMany, [int? precision]) {
  plural_rules.startRuleEvaluation(howMany, precision);
  var verifiedLocale = Intl.verifiedLocale(locale, plural_rules.localeHasPluralRules, onFailure: (locale) => 'default');
  if (_cachedPluralLocale == verifiedLocale) {
    return _cachedPluralRule;
  } else {
    _cachedPluralRule = plural_rules.pluralRules[verifiedLocale]; // null-safety
    _cachedPluralLocale = verifiedLocale;
    return _cachedPluralRule;
  }
}

class Arguments {
  final List<dynamic> positional;
  final Map<Symbol, dynamic> named;
  Arguments(this.positional, this.named);
}
