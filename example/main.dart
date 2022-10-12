import 'package:fluent/fluent.dart';

void main() {
    FluentBundle bundle = FluentBundle("en-GB");
		bundle.addMessages('''your-score =
    { NUMBER(\$score, minimumFractionDigits: 1) ->
        [0.0]   You scored zero points. What happened?
       *[other] You scored { NUMBER(\$score, minimumFractionDigits: 1) } points.
    }''');
		String? translated = bundle.format("your-score", args: {'score': 0.0});
		print(translated);
		translated = bundle.format("your-score", args: {'score': 3.14});
		print(translated);
}