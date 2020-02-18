
class TestBundle {

    String get hello => "Hello, world!";

    String removeBookmark({String title}) =>  "Are you sure you want to remove  $title?";

    String remove_bookmark2({String title}) => "Really remove $title?";

    String get _brand_name => "Firefox";

    String get installing => "Installing $_brand_name.";

    String get opening_brace => "This message features an opening curly brace: " + "{" + ".";

    String get closing_brace => "This message features a closing curly brace:  " + "}" + ".";

    String get blank_is_removed => "This message starts with no blanks.";

    String get blank_is_preserved => "    " + "This message starts with 4 spaces.";

    String get leading_bracket => 
'''This message has an opening square bracket
at the beginning of the third line:
'''+ "["  + '''.
''';
    String get attribute_how_to => 
    '''To add an attribute to this messages, write
    {".attr = Value"} on a new line.
    .attr = An actual attribute (not part of the text value above)''';

    String get literal_quote1 => "Text in \"double quotes\".";

    String get literal_quote2 => "Text in \"double quotes\".";

    String get privacy_label => "Privacy\u00A0Policy";

    String get which_dash1 => "It's a dash—or is it?";

    String get which_dash2 => "It's a dash\u2014or is it?";

    String get tears_of_joy1 => "\U01F602";

    String get tears_of_joy2 => "😂";

    String get single => "Text can be written in a single line.";

    String get multi => '''Text can also span multiple lines
as long as each new line is indented
by at least one space.''';

    String get block => '''
Sometimes it's more readable to format
multiline text as a "block", which means
starting it on a new line. All lines must
be indented by at least one space.''';

    String get leading_spaces =>  "This message's value starts with the word \"This\".";

    String get leading_lines =>


    '''This message's value starts with the word \"This\".
The blank lines under the identifier are ignored.''';

    String get blank_lines =>

    '''The blank line above this line is ignored.
This is a second line of the value.

The blank line above this line is preserved.''';

    String get multiline2 =>
    '''  This message starts with 2 spaces on the first
first line of its value. The first 4 spaces of indent
are removed from all lines.''';

    String get multiline3 => '''This message has 4 spaces of indent
    on the second line of its value. The first
line is not considered indented at all.''';

    String get multiline4 => '''This message has 4 spaces of indent
    on the second line of its value. The first
line is not considered indented at all.''';

    String get multiline5 => '''This message ends up having no indent
on the second line of its value.''';

    String welcome(String user) => "Welcome, $user!";

    String unread_emails(String user, int email_count) => "{ $user } has $email_count unread emails.";

    String time_elapsed(double duration) => "Time elapsed: ${duration}s.";

    String time_elapsed2(double duration) => "Time elapsed: ${NUMBER(duration, maximumFractionDigits: 0)}s.";

    String get menu_save => "Save";
    String get help_menu_save => "Click $menu_save to save the file.";

    String get _brand_name1 => "Firefox";
    String get installing2 => "Installing $_brand_name1.";

    String emails(int unreadEmails) {
        switch (unreadEmails) {
            case 1:
                return "You have one unread email.";
            default:
                return "You have $unreadEmails unread emails.";
        }
    }

    String your_score(double score) {
        switch(NUMBER(score, minimumFractionDigits: 1)) {
            case "0.0":
                return "You scored zero points. What happened?";
            default:
                return "You scored ${NUMBER(score, minimumFractionDigits: 1)} points.";
        }
    }

    String get login_input => "Predefined value";
    String get login_input__placeholder => "email@example.com";
    String get login_input__aria_label  => "Login input value";
    String get login_input__title => "Type your login email";

    String NUMBER(double number, {int minimumFractionDigits, int maximumFractionDigits, String type}) {
        return number.toString();
    }

}