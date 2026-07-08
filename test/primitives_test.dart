// Ported from fluent.js fluent-bundle/test/primitives_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	group('Numbers', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''one     = { 1 }
select  = { 1 ->
   *[0] Zero
    [1] One
}''');
		});

		test('can be used in a placeable', () {
			expect(bundle.format("one"), "1");
		});

		test('can be used as a selector', () {
			expect(bundle.format("select"), "One");
		});
	});

	group('Simple string value', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo               = Foo

placeable-literal = { "Foo" } Bar
placeable-message = { foo } Bar

selector-literal = { "Foo" ->
   *[Foo] Member 1
}

bar =
    .attr = Bar Attribute

placeable-attr   = { bar.attr }

-baz = Baz
    .attr = BazAttribute

selector-attr    = { -baz.attr ->
   *[BazAttribute] Member 3
}''');
		});

		test('can be used as a value', () {
			expect(bundle.format("foo"), "Foo");
		});

		test('can be used in a placeable', () {
			expect(bundle.format("placeable-literal"), "Foo Bar");
		});

		test('can be a value of a message referenced in a placeable', () {
			expect(bundle.format("placeable-message"), "Foo Bar");
		});

		test('can be a selector', () {
			expect(bundle.format("selector-literal"), "Member 1");
		});

		test('can be used as an attribute value', () {
			expect(bundle.format("bar", attribute: "attr"), "Bar Attribute");
		});

		test('can be a value of an attribute used in a placeable', () {
			expect(bundle.format("placeable-attr"), "Bar Attribute");
		});

		test('can be a value of an attribute used as a selector', () {
			expect(bundle.format("selector-attr"), "Member 3");
		});
	});

	group('Complex string value', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo               = Foo
bar               = { foo }Bar

placeable-message = { bar }Baz

baz =
    .attr = { bar }BazAttribute

placeable-attr = { baz.attr }

selector-attr = { baz.attr ->
    [FooBarBazAttribute] FooBarBaz
   *[other] Other
}''');
		});

		test('can be used as a value', () {
			expect(bundle.format("bar"), "FooBar");
		});

		test('can be a value of a message referenced in a placeable', () {
			expect(bundle.format("placeable-message"), "FooBarBaz");
		});

		test('can be used as an attribute value', () {
			expect(bundle.format("baz", attribute: "attr"), "FooBarBazAttribute");
		});

		test('can be a value of an attribute used in a placeable', () {
			expect(bundle.format("placeable-attr"), "FooBarBazAttribute");
		});

		test('can be a value of an attribute used as a selector', () {
			expect(bundle.format("selector-attr"), "FooBarBaz");
		});
	});
}
