library fluent;

import 'package:intl/intl.dart';
import 'package:intl/src/plural_rules.dart' as plural_rules;

import 'ast.dart';
import 'builtin.dart';
import 'parser.dart';
import 'error.dart';
import 'scope.dart';

typedef String TextTransform(String text);
String identity(String s) => s;


class FluentBundle {

    // The maximum number of placeables which can be expanded in a single call to
    // `formatPattern`. The limit protects against the Billion Laughs and Quadratic
    // Blowup attacks. See https://msdn.microsoft.com/en-us/magazine/ee335713.aspx.
    static const MAX_PLACEABLES = 100;

    // Unicode bidi isolation characters.
    static const FSI = "\u2068";
    static const PDI = "\u2069";

    final String locale;
    final bool useIsolating;
    final TextTransform transform;

    final Map<String, Message> _messages = {};
    final Map<String, Function> functions = {
        'NUMBER': NUMBER,
        'DATETIME': DATETIME,
    };

    FluentBundle(this.locale, {this.useIsolating = true, this.transform = identity });

    void addMessages(String source) {
        FluentParser parser = FluentParser(source);
        Resource resource = parser.parse();
        for(Message message in resource.body) {
            _messages[message.id] = message;
        }
    }

    /**
     * Check if a message is present in the bundle.
     *
     * @param id - The identifier of the message to check.
     */
    bool hasMessage(String id) {
        return this._messages.containsKey(id);
    }

    String format(String id,  {Map<String, dynamic> args = const {}, List<Error> errors}) {
        Message message = this._messages[id];
        if(message==null) {
            return null;
        }
        Pattern pattern = message.value;
        // Resolve a simple pattern without creating a scope. No error handling is
        // required; by definition simple patterns don't have placeables.
        if(pattern.elements.length==1) {
            PatternElement element = pattern.elements.first;
            if(element is TextElement) {
                return this.transform(element.value);
            }
        }
        // Resolve a complex pattern.
        final scope = Scope(this, errors, args);
        try {
            return resolvePattern(scope, pattern);
        }
        catch(err) {
            if(errors!=null) {
                errors.add(err);
                return null;
            }
            throw err;
        }
    }

    // Resolve a pattern (a complex string with placeables).
    String resolvePattern(Scope scope, Pattern pattern) {
        if (scope.dirty.contains(pattern)) {
            scope.reportError(new RangeError("Cyclic reference"));
            return null;
        }

        // Tag the pattern as dirty for the purpose of the current resolution.
        scope.dirty.add(pattern);
        StringBuffer sb = StringBuffer();

        // Wrap interpolations with Directional Isolate Formatting characters
        // only when the pattern has more than one element.
        bool _useIsolating = useIsolating && pattern.elements.length > 1;

        for(var element in pattern.elements) {
            if(element is TextElement) {
                sb.write(transform(element.value));
                continue;
            }

            scope.placeables++;
            if (scope.placeables > MAX_PLACEABLES) {
                scope.dirty.remove(pattern);
                // This is a fatal error which causes the resolver to instantly bail out
                // on this pattern. The length check protects against excessive memory
                // usage, and throwing protects against eating up the CPU when long
                // placeables are deeply nested.
                throw RangeError("Too many placeables expanded: ${scope.placeables}, max allowed is ${MAX_PLACEABLES}");
            }

            if (_useIsolating) {
                sb.write(FSI);
            }

            sb.write(resolveExpression(scope, element));

            if (_useIsolating) {
                sb.write(PDI);
            }
        }

        scope.dirty.remove(pattern);
        return sb.toString();
    }

    // Resolve an expression to a Fluent type.
    String resolveExpression(Scope scope, Expression expr) {
        if(expr is StringLiteral) {
            return expr.value;
        }
        else if(expr is NumberLiteral) {
            return NUMBER(expr.value, minimumFractionDigits: expr.precision);
        }
        else if(expr is VariableReference) {
            return resolveVariableReference(scope, expr);
        }
        else if(expr is MessageReference) {
            return resolveMessageReference(scope, expr);
        }
        else if(expr is TermReference) {
            return resolveTermReference(scope, expr);
        }
        else if(expr is FunctionReference) {
            return resolveFunctionReference(scope, expr);
        }
        else if(expr is SelectExpression) {
            return resolveSelectExpression(scope, expr);
        }
        else {
            return null;
        }
    }

    // Resolve a reference to a variable.
    String resolveVariableReference(Scope scope, VariableReference name) {
        var arg;
        if (scope.params!=null) {
            // We're inside a TermReference. It's OK to reference undefined parameters.
            if (scope.params.containsKey(name.name)) {
                arg = scope.params[name.name];
            }
            else {
                return null;
            }
        }
        else if(scope.args.containsKey(name.name)) {
            // We're in the top-level Pattern or inside a MessageReference. Missing
            // variables references produce ReferenceErrors.
            arg = scope.args[name.name];
        }
        else {
            scope.reportError(ReferenceError("Unknown variable: ${name.name}"));
            return null;
        }

        if(arg is String) {
            return arg;
        }
        else if(arg is num) {
            return NUMBER(arg);
        }
        else if(arg is DateTime) {
            return DATETIME(arg);
        }
        else {
            scope.reportError(UnsupportedError("Variable type not supported: ${name.name}, ${arg.runtimeType}"));
            return null;
        }
    }

    // Resolve a reference to another message.
    String resolveMessageReference(Scope scope, MessageReference reference) {
        String name = reference.name;
        String attr = reference.attr;
        final message = this._messages[name];
        if(message==null) {
            scope.reportError(ReferenceError("Unknown message: ${name}"));
            return null;
        }
        if (attr!=null) {
            final attribute = message.attributes[attr];
            if(attribute!=null) {
                return resolvePattern(scope, attribute);
            }
            scope.reportError(ReferenceError("Unknown attribute: $attr"));
            return null;
        }
        if (message.value!=null) {
            return resolvePattern(scope, message.value);
        }

        scope.reportError(ReferenceError("No value: $name"));
        return null;
    }

    // Resolve a call to a Term with key-value arguments.
    String resolveTermReference(Scope scope, TermReference reference) {
        String name = reference.name;
        String attr = reference.attr;
        List<Argument> args = reference.arguments;
        final term = _messages[name];
        if(term==null) {
            scope.reportError(ReferenceError("Unknown term: $name"));
            return null;
        }
        if (attr!=null) {
            final attribute = term.attributes[attr];
             if (attribute!=null) {
                 // Every TermReference has its own variables.
                 scope.params = getArguments(scope, args).named;
                 final resolved = resolvePattern(scope, attribute);
                 scope.params = null;
                 return resolved;
             }
             scope.reportError(ReferenceError("Unknown attribute: $attr"));
             return null;
        }

        scope.params = getArguments(scope, args).named;
        final resolved = resolvePattern(scope, term.value);
        scope.params = null;
        return resolved;
    }

    // Resolve a call to a Function with positional and key-value arguments.
    String resolveFunctionReference(Scope scope, FunctionReference reference) {
        String name = reference.name;
        var args = reference.arguments;
        var func = this.functions[name];
        if(func==null) {
            scope.reportError(ReferenceError("Unknown function: $name()"));
            return null;
        }

        if(!(func is Function)) {
            scope.reportError(AssertionError("Function $name() is not callable"));
            return null;
        }

        try {
            final resolved = getArguments(scope, args);
            return Function.apply(func, resolved.positional, resolved.named);
        } catch (err) {
            scope.reportError(err);
            return null;
        }
    }

    // Resolve a select expression to the member object.
    String resolveSelectExpression(Scope scope, SelectExpression select) {
        final selector = select.selector;
        final variants = select.variants;
        final sel = resolveExpression(scope, selector);
        if(sel==null) {
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
        for(Argument arg in args) {
            if(arg is PositionalArgument) {
                positional.add(resolveExpression(scope, arg.value));
            }
            else if(arg is NamedArgument) {
                Symbol symbol = Symbol(arg.name);
                named[symbol] = resolveExpression(scope, arg.value);
            }
        }
        return Arguments(positional, named);
    }

    // Helper: match a variant key to the given selector.
    bool match(Scope scope, dynamic selector, dynamic key) {
        if (key == selector) {
            // Both are strings.
            return true;
        }
        // Ignoring options too, e.g. minimumFractionDigits.
        if (key is num && selector is num && key == selector) {
            return true;
        }

        if (selector is num && key is String) {
            plural_rules.PluralRule pluralRule = _pluralRule(locale, selector);
            plural_rules.PluralCase pluralCase = pluralRule();
            String category = pluralCase.toString().split('.').last.toLowerCase();
            if (key.toLowerCase() == category) {
                return true;
            }
        }
        return false;
    }

    // Helper: resolve the default variant from a list of variants.
    String getDefault(Scope scope, List<Variant> variants) {
        for(Variant variant in variants) {
            if(variant.isDefault) {
                return resolvePattern(scope, variant.value);
            }
        }

        scope.reportError(RangeError("No default"));
        return null;
    }

    static plural_rules.PluralRule _cachedPluralRule;
    static String _cachedPluralLocale;

    static plural_rules.PluralRule _pluralRule(String locale, num howMany, [int precision]) {
        plural_rules.startRuleEvaluation(howMany, precision);
        var verifiedLocale = Intl.verifiedLocale(
            locale, plural_rules.localeHasPluralRules,
            onFailure: (locale) => 'default');
        if (_cachedPluralLocale == verifiedLocale) {
            return _cachedPluralRule;
        } else {
            _cachedPluralRule = plural_rules.pluralRules[verifiedLocale];
            _cachedPluralLocale = verifiedLocale;
            return _cachedPluralRule;
        }
    }

}

class Arguments {
    final List<dynamic> positional;
    final Map<Symbol, dynamic> named;
    Arguments(this.positional, this.named);
}