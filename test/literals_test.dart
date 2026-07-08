// Ported from fluent.js fluent-bundle/test/literals_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	late FluentBundle bundle;

	setUp(() {
		bundle = FluentBundle("en-US");
	});

	test('a matching string literal selector', () {
		bundle.addMessages('''foo = { "a" ->
    [a] A
   *[b] B
}''');
		List<Error> errs = [];
		expect(bundle.format("foo", errors: errs), "A");
		expect(errs.length, 0);
	});

	test('a non-matching string literal selector', () {
		bundle.addMessages('''foo = { "c" ->
    [a] A
   *[b] B
}''');
		List<Error> errs = [];
		expect(bundle.format("foo", errors: errs), "B");
		expect(errs.length, 0);
	});

	test('a matching number literal selector', () {
		bundle.addMessages('''foo = { 0 ->
    [0] A
   *[1] B
}''');
		List<Error> errs = [];
		expect(bundle.format("foo", errors: errs), "A");
		expect(errs.length, 0);
	});

	test('a non-matching number literal selector', () {
		bundle.addMessages('''foo = { 2 ->
    [0] A
   *[1] B
}''');
		List<Error> errs = [];
		expect(bundle.format("foo", errors: errs), "B");
		expect(errs.length, 0);
	});

	test('a number literal selector matching a plural category', () {
		bundle.addMessages('''foo = { 1 ->
    [one] A
   *[other] B
}''');
		List<Error> errs = [];
		expect(bundle.format("foo", errors: errs), "A");
		expect(errs.length, 0);
	});
}
