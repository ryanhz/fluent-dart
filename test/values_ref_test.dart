// Ported from fluent.js fluent-bundle/test/values_ref_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	late FluentBundle bundle;

	setUp(() {
		bundle = FluentBundle("en-US");
		bundle.addMessages('''key1 = Value 1
-key2 = { \$sel ->
    [a] A2
   *[b] B2
}
key3 = Value { 3 }
-key4 = { \$sel ->
    [a] A{ 4 }
   *[b] B{ 4 }
}
key5 =
    .a = A5
    .b = B5

ref1 = { key1 }
ref2 = { -key2 }
ref3 = { key3 }
ref4 = { -key4 }
ref5 = { key5 }

ref6 = { -key2(sel: "a") }
ref7 = { -key2(sel: "b") }

ref8 = { -key4(sel: "a") }
ref9 = { -key4(sel: "b") }

ref10 = { key5.a }
ref11 = { key5.b }
ref12 = { key5.c }

ref13 = { key6 }
ref14 = { key6.a }

ref15 = { -key6 }
ref16 = { -key6.a ->
    *[a] A
}''');
	});

	test('references the value', () {
		List<Error> errs = [];
		expect(bundle.format("ref1", errors: errs), "Value 1");
		expect(errs.length, 0);
	});

	test('references the default variant', () {
		List<Error> errs = [];
		expect(bundle.format("ref2", errors: errs), "B2");
		expect(errs.length, 0);
	});

	test('references the value if it is a pattern', () {
		List<Error> errs = [];
		expect(bundle.format("ref3", errors: errs), "Value 3");
		expect(errs.length, 0);
	});

	test('references the default variant if it is a pattern', () {
		List<Error> errs = [];
		expect(bundle.format("ref4", errors: errs), "B4");
		expect(errs.length, 0);
	});

	test('falls back to id if there is no value', () {
		List<Error> errs = [];
		expect(bundle.format("ref5", errors: errs), "{key5}");
		expect(errs.length, 1);
	});

	test('references the variants', () {
		List<Error> errs = [];
		expect(bundle.format("ref6", errors: errs), "A2");
		expect(bundle.format("ref7", errors: errs), "B2");
		expect(errs.length, 0);
	});

	test('references the variants which are patterns', () {
		List<Error> errs = [];
		expect(bundle.format("ref8", errors: errs), "A4");
		expect(bundle.format("ref9", errors: errs), "B4");
		expect(errs.length, 0);
	});

	test('references the attributes', () {
		List<Error> errs = [];
		expect(bundle.format("ref10", errors: errs), "A5");
		expect(bundle.format("ref11", errors: errs), "B5");
		expect(bundle.format("ref12", errors: errs), "{key5.c}");
		expect(errs.length, 1);
	});

	test('missing message reference', () {
		List<Error> errs = [];
		expect(bundle.format("ref13", errors: errs), "{key6}");
		expect(bundle.format("ref14", errors: errs), "{key6}");
		expect(errs.length, 2);
	});

	test('missing term reference', () {
		List<Error> errs = [];
		expect(bundle.format("ref15", errors: errs), "{-key6}");
		expect(bundle.format("ref16", errors: errs), "A");
		expect(errs.length, 2);
	});
}
