import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
  test('hello', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages("hello = Hello, world!");
    expect(bundle.format("hello", args: {}), "Hello, world!");
  });
  test('remove-bookmark', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# \$title (String) - The title of the bookmark to remove.
remove-bookmark = Are you sure you want to remove { \$title }?''');
    String translated = bundle.format("remove-bookmark", args: {'title': 'Google⁩'});
    expect(translated, "Are you sure you want to remove Google⁩?");
  });
  test('installing', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''-brand-name = Firefox
installing = Installing { -brand-name }.''');
    String translated = bundle.format("installing");
    expect(translated, "Installing Firefox.");
  });
  test('opening-brace', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''opening-brace = This message features an opening curly brace: {"{"}.''');
    String translated = bundle.format("opening-brace");
    expect(translated, "This message features an opening curly brace: {.");
  });
  test('closing-brace', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''closing-brace = This message features a closing curly brace: {"}"}.''');
    String translated = bundle.format("closing-brace");
    expect(translated, "This message features a closing curly brace: }.");
  });
  test('blank-is-removed', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''blank-is-removed =     This message starts with no blanks.''');
    String translated = bundle.format("blank-is-removed");
    expect(translated, "This message starts with no blanks.");
  });
  test('blank-is-preserved', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''blank-is-preserved = {"    "}This message starts with 4 spaces.''');
    String translated = bundle.format("blank-is-preserved");
    expect(translated, "    This message starts with 4 spaces.");
  });
  test('leading-bracket', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''leading-bracket =
    This message has an opening square bracket
    at the beginning of the third line:
    {"["}.
''');
    String translated = bundle.format("leading-bracket");
    expect(translated, '''This message has an opening square bracket
at the beginning of the third line:
[.''');
  });
  test('attribute-how-to', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''attribute-how-to =
    To add an attribute to this messages, write
    {".attr = Value"} on a new line.
    .attr = An actual attribute (not part of the text value above)
''');
    String translated = bundle.format("attribute-how-to");
    expect(translated, '''To add an attribute to this messages, write
.attr = Value on a new line.''');
  });
  test('use-attribute', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''attribute-how-to =
    To add an attribute to this messages, write
    {".attr = Value"} on a new line.
    .attr = An actual attribute (not part of the text value above)
''');
    String translated = bundle.format("attribute-how-to", attribute: "attr");
    expect(translated, '''An actual attribute (not part of the text value above)''');
  });
  test('literal-quote1', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# This is OK, but cryptic and hard to read and edit.
literal-quote1 = Text in {"\\""}double quotes{"\\""}.''');
    String translated = bundle.format("literal-quote1");
    expect(translated, '''Text in "double quotes".''');
  });
  test('literal-quote2', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# This is preferred. Just use the actual double quote character.
literal-quote2 = Text in "double quotes".''');
    String translated = bundle.format("literal-quote2");
    expect(translated, '''Text in "double quotes".''');
  });
  test('privacy-label', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''privacy-label = Privacy{"\\u00A0"}Policy''');
    String translated = bundle.format("privacy-label");
    expect(translated, '''Privacy\u00A0Policy''');
  });
  test('which-dash1', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# The dash character is an EM DASH but depending on the font face,
# it might look like an EN DASH.
which-dash1 = It's a dash—or is it?''');
    String translated = bundle.format("which-dash1");
    expect(translated, '''It's a dash—or is it?''');
  });
  test('which-dash2', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# Using a Unicode escape sequence makes the intent clear.
which-dash2 = It's a dash{"\\u2014"}or is it?''');
    String translated = bundle.format("which-dash2");
    expect(translated, '''It's a dash\u2014or is it?''');
  });
  test('tears-of-joy1', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# This will work fine, but the codepoint can be considered
# cryptic by other translators.
tears-of-joy1 = {"\\U01F602"}''');
    String translated = bundle.format("tears-of-joy1");
    expect(translated, '''😂''');
  });
  test('tears-of-joy2', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''# This is preferred. You can instantly see what the Unicode
# character used here is.
tears-of-joy2 = 😂''');
    String translated = bundle.format("tears-of-joy2");
    expect(translated, '''😂''');
  });
  test('single', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages("single = Text can be written in a single line.");
    expect(bundle.format("single"), "Text can be written in a single line.");
  });
  test('multi', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multi = Text can also span multiple lines
    as long as each new line is indented
    by at least one space.''');
    String translated = bundle.format("multi");
    expect(translated, '''Text can also span multiple lines
as long as each new line is indented
by at least one space.''');
  });
  test('block', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''block =
    Sometimes it's more readable to format
    multiline text as a "block", which means
    starting it on a new line. All lines must
    be indented by at least one space.''');
    String translated = bundle.format("block");
    expect(translated, '''Sometimes it's more readable to format
multiline text as a "block", which means
starting it on a new line. All lines must
be indented by at least one space.''');
  });
  test('leading-spaces', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''leading-spaces =     This message's value starts with the word "This".''');
    String translated = bundle.format("leading-spaces");
    expect(translated, '''This message's value starts with the word "This".''');
  });
  test('leading-lines', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''leading-lines =


    This message's value starts with the word "This".
    The blank lines under the identifier are ignored.''');
    String translated = bundle.format("leading-lines");
    expect(translated, '''This message's value starts with the word "This".
The blank lines under the identifier are ignored.''');
  });
  test('blank-lines', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''blank-lines =

    The blank line above this line is ignored.
    This is a second line of the value.

    The blank line above this line is preserved.''');
    String translated = bundle.format("blank-lines");
    expect(translated, '''The blank line above this line is ignored.
This is a second line of the value.

The blank line above this line is preserved.''');
  });
  test('multiline1', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multiline1 =
    This message has 4 spaces of indent
        on the second line of its value.''');
    String translated = bundle.format("multiline1");
    expect(translated, '''This message has 4 spaces of indent
    on the second line of its value.''');
  });
  test('multiline2', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multiline2 =
      This message starts with 2 spaces on the first
    first line of its value. The first 4 spaces of indent
    are removed from all lines.''');
    String translated = bundle.format("multiline2");
    expect(translated, '''  This message starts with 2 spaces on the first
first line of its value. The first 4 spaces of indent
are removed from all lines.''');
  });
  test('multiline3', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multiline3 = This message has 4 spaces of indent
        on the second line of its value. The first
    line is not considered indented at all.''');
    String translated = bundle.format("multiline3");
    expect(translated, '''This message has 4 spaces of indent
    on the second line of its value. The first
line is not considered indented at all.''');
  });
  test('multiline4', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multiline4 =     This message has 4 spaces of indent
        on the second line of its value. The first
    line is not considered indented at all.''');
    String translated = bundle.format("multiline4");
    expect(translated, '''This message has 4 spaces of indent
    on the second line of its value. The first
line is not considered indented at all.''');
  });
  test('multiline5', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''multiline5 = This message ends up having no indent
        on the second line of its value.''');
    String translated = bundle.format("multiline5");
    expect(translated, '''This message ends up having no indent
on the second line of its value.''');
  });
  test('welcome', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''welcome = Welcome, { \$user }!''');
    String translated = bundle.format("welcome", args: {'user': "Ryan"});
    expect(translated, '''Welcome, Ryan!''');
  });
  test('unread-emails', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''unread-emails = { \$user } has { \$email-count } unread emails.''');
    String translated = bundle.format("unread-emails", args: {'user': "Ryan", 'email-count': 4});
    expect(translated, '''Ryan has 4 unread emails.''');
  });
  test('time-elapsed', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''time-elapsed = Time elapsed: { \$duration }s.''');
    String translated = bundle.format("time-elapsed", args: {'duration': 4.3});
    expect(translated, '''Time elapsed: 4.3s.''');
  });
  test('time-elapsed2', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''time-elapsed2 = Time elapsed: { NUMBER(\$duration, maximumFractionDigits: 0) }s.''');
    String translated = bundle.format("time-elapsed2", args: {'duration': 4.3});
    expect(translated, '''Time elapsed: 4s.''');
  });
  test('help-menu-save', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''menu-save = Save
help-menu-save = Click { menu-save } to save the file.''');
    String translated = bundle.format("help-menu-save");
    expect(translated, '''Click Save to save the file.''');
  });
  test('emails', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''emails =
    { \$unreadEmails ->
        [one] You have one unread email.
       *[other] You have { \$unreadEmails } unread emails.
    }''');
    String translated = bundle.format("emails", args: {'unreadEmails': 1});
    expect(translated, '''You have one unread email.''');
    translated = bundle.format("emails", args: {'unreadEmails': 20});
    expect(translated, '''You have 20 unread emails.''');
  });
  test('your-score', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''your-score =
    { NUMBER(\$score, minimumFractionDigits: 1) ->
        [0.0]   You scored zero points. What happened?
       *[other] You scored { NUMBER(\$score, minimumFractionDigits: 1) } points.
    }''');
    String translated = bundle.format("your-score", args: {'score': 0.0});
    expect(translated, '''You scored zero points. What happened?''');
    translated = bundle.format("your-score", args: {'score': 3.14});
    expect(translated, '''You scored 3.14 points.''');
  });
  test('shared-photos', () {
    FluentBundle bundle = FluentBundle("en-GB");
    bundle.addMessages('''shared-photos =
    {\$userName} {\$photoCount ->
        [one] added a new photo
       *[other] added {\$photoCount} new photos
    } to {\$userGender ->
        [male] his stream
        [female] her stream
       *[other] their stream
    }.''');
    String translated =
        bundle.format("shared-photos", args: {'userName': "Anne", 'userGender': "female", "photoCount": 3});
    expect(translated, '''Anne added 3 new photos to her stream.''');
    translated = bundle.format("shared-photos", args: {'userName': "Tom", 'userGender': "male", "photoCount": 1});
    expect(translated, '''Tom added a new photo to his stream.''');
  });
}
