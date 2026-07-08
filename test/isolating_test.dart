// Ported from fluent.js fluent-bundle/test/isolating_test.js
// ignore_for_file: text_direction_code_point_in_literal

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

const String fsi = '⁨';
const String pdi = '⁩';

void main() {
	group('Isolating interpolations', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US", useIsolating: true);
			bundle.addMessages('''foo = Foo
bar = { foo } Bar
baz = { \$arg } Baz
qux = { bar } { baz }''');
		});

		test('isolates interpolated message references', () {
			List<Error> errs = [];
			expect(bundle.format("bar", errors: errs), "${fsi}Foo$pdi Bar");
			expect(errs.length, 0);
		});

		test('isolates interpolated string-typed variables', () {
			List<Error> errs = [];
			expect(bundle.format("baz", args: {'arg': "Arg"}, errors: errs), "${fsi}Arg$pdi Baz");
			expect(errs.length, 0);
		});

		test('isolates interpolated number-typed variables', () {
			List<Error> errs = [];
			expect(bundle.format("baz", args: {'arg': 1}, errors: errs), "${fsi}1$pdi Baz");
			expect(errs.length, 0);
		});

		test('isolates interpolated date-typed variables', () {
			List<Error> errs = [];
			FluentValue arg = FluentDateTime(DateTime(2016, 9, 29), pattern: "M/d/yyyy");
			expect(bundle.format("baz", args: {'arg': arg}, errors: errs), "${fsi}9/29/2016$pdi Baz");
			expect(errs.length, 0);
		});

		test('isolates complex interpolations', () {
			List<Error> errs = [];
			String val = bundle.format("qux", args: {'arg': "Arg"}, errors: errs)!;
			String expectedBar = "$fsi${fsi}Foo$pdi Bar$pdi";
			String expectedBaz = "$fsi${fsi}Arg$pdi Baz$pdi";
			expect(val, "$expectedBar $expectedBaz");
			expect(errs.length, 0);
		});
	});

	group('Skip isolation cases', () {
		test('skips isolation if the only element is a placeable', () {
			FluentBundle bundle = FluentBundle("en-US", useIsolating: true);
			bundle.addMessages('''-brand-short-name = Amaya
foo = { -brand-short-name }''');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "Amaya");
			expect(errs.length, 0);
		});
	});
}
