// Ported from fluent.js fluent-bundle/test/select_expressions_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	late FluentBundle bundle;

	setUp(() {
		bundle = FluentBundle("en-US");
	});

	test('missing selector falls back to the default variant', () {
		bundle.addMessages('''select = {\$none ->
    [a] A
   *[b] B
}''');
		List<Error> errs = [];
		expect(bundle.format("select", args: {}, errors: errs), "B");
		expect(errs.length, 1);
	});

	group('string selectors', () {
		setUp(() {
			bundle.addMessages('''select = {\$selector ->
    [a] A
   *[b] B
}''');
		});

		test('matching selector', () {
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': "a"}, errors: errs), "A");
			expect(errs.length, 0);
		});

		test('non-matching selector', () {
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': "c"}, errors: errs), "B");
			expect(errs.length, 0);
		});
	});

	group('number selectors', () {
		setUp(() {
			bundle.addMessages('''select = {\$selector ->
    [0] A
   *[1] B
}''');
		});

		test('matching selector', () {
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': 0}, errors: errs), "A");
			expect(errs.length, 0);
		});

		test('non-matching selector', () {
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': 2}, errors: errs), "B");
			expect(errs.length, 0);
		});
	});

	group('plural categories', () {
		test('matching number selector', () {
			bundle.addMessages('''select = {\$selector ->
    [one] A
   *[other] B
}''');
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': 1}, errors: errs), "A");
			expect(errs.length, 0);
		});

		test('matching string selector', () {
			bundle.addMessages('''select = {\$selector ->
    [one] A
   *[other] B
}''');
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': "one"}, errors: errs), "A");
			expect(errs.length, 0);
		});

		test('non-matching number selector', () {
			bundle.addMessages('''select = {\$selector ->
    [one] A
   *[default] D
}''');
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': 2}, errors: errs), "D");
			expect(errs.length, 0);
		});

		test('non-matching string selector', () {
			bundle.addMessages('''select = {\$selector ->
    [one] A
   *[default] D
}''');
			List<Error> errs = [];
			expect(bundle.format("select", args: {'selector': "other"}, errors: errs), "D");
			expect(errs.length, 0);
		});
	});
}
