
import 'package:fluent/fluent.dart';
import 'package:test/test.dart';


void main() {
	test('parse ftl file', () {
		FluentBundle bundle = FluentBundle("en-GB");
		bundle.addMessages("hello = Hello, world!");
		expect(bundle.format("hello", {}), "Hello, world!");
		expect(() => 2/0, double.infinity);
	});
}
