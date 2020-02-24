hello = Hello, world!
# $title (String) - The title of the bookmark to remove.
remove-bookmark = Are you sure you want to remove { $title }?

# $title (String) - The title of the bookmark to remove.
remove-bookmark2 = Really remove { $title }?

-brand-name = Firefox
installing = Installing { -brand-name }.
opening-brace = This message features an opening curly brace: {"{"}.
closing-brace = This message features a closing curly brace: {"}"}.
blank-is-removed =     This message starts with no blanks.
blank-is-preserved = {"    "}This message starts with 4 spaces.
leading-bracket =
    This message has an opening square bracket
    at the beginning of the third line:
    {"["}.
attribute-how-to =
    To add an attribute to this messages, write
    {".attr = Value"} on a new line.
    .attr = An actual attribute (not part of the text value above)

# This is OK, but cryptic and hard to read and edit.
literal-quote1 = Text in {"\""}double quotes{"\""}.

# This is preferred. Just use the actual double quote character.
literal-quote2 = Text in "double quotes".

privacy-label = Privacy{"\u00A0"}Policy

# The dash character is an EM DASH but depending on the font face,
# it might look like an EN DASH.
which-dash1 = It's a dash—or is it?

# Using a Unicode escape sequence makes the intent clear.
which-dash2 = It's a dash{"\u2014"}or is it?

# This will work fine, but the codepoint can be considered
# cryptic by other translators.
tears-of-joy1 = {"\U01F602"}

# This is preferred. You can instantly see what the Unicode
# character used here is.
tears-of-joy2 = 😂

single = Text can be written in a single line.

multi = Text can also span multiple lines
    as long as each new line is indented
    by at least one space.

block =
    Sometimes it's more readable to format
    multiline text as a "block", which means
    starting it on a new line. All lines must
    be indented by at least one space.

leading-spaces =     This message's value starts with the word "This".
leading-lines =


    This message's value starts with the word "This".
    The blank lines under the identifier are ignored.
blank-lines =

    The blank line above this line is ignored.
    This is a second line of the value.

    The blank line above this line is preserved.
multiline1 =
    This message has 4 spaces of indent
        on the second line of its value.
multiline2 =
      This message starts with 2 spaces on the first
    first line of its value. The first 4 spaces of indent
    are removed from all lines.
multiline3 = This message has 4 spaces of indent
        on the second line of its value. The first
    line is not considered indented at all.
# Same value as multiline3 above.
multiline4 =     This message has 4 spaces of indent
        on the second line of its value. The first
    line is not considered indented at all.
multiline5 = This message ends up having no indent
        on the second line of its value.

welcome = Welcome, { $user }!
unread-emails = { $user } has { $email-count } unread emails.

# $duration (Number) - The duration in seconds.
time-elapsed = Time elapsed: { $duration }s.

# $duration (Number) - The duration in seconds.
time-elapsed2 = Time elapsed: { NUMBER($duration, maximumFractionDigits: 0) }s.

menu-save = Save
help-menu-save = Click { menu-save } to save the file.

-brand-name = Firefox
installing = Installing { -brand-name }.

emails =
    { $unreadEmails ->
        [one] You have one unread email.
       *[other] You have { $unreadEmails } unread emails.
    }

your-score =
    { NUMBER($score, minimumFractionDigits: 1) ->
        [0.0]   You scored zero points. What happened?
       *[other] You scored { NUMBER($score, minimumFractionDigits: 1) } points.
    }

login-input = Predefined value
    .placeholder = email@example.com
    .aria-label = Login input value
    .title = Type your login email



about = About { -brand-name }.
update-successful = { -brand-name } has been updated.

# A contrived example to demonstrate how variables
# can be passed to terms.
-https = https://{ $host }
visit = Visit { -https(host: "example.com") } for more information.

-brand-name1 =
    { $case ->
       *[nominative] Firefox
        [locative] Firefoxa
    }

# "About Firefox."
about1 = Informacje o { -brand-name1(case: "locative") }.

-brand-name2 = Aurora
    .gender = feminine

update-successful2 =
    { -brand-name.gender ->
        [masculine] { -brand-name2} został zaktualizowany.
        [feminine] { -brand-name2 } została zaktualizowana.
       *[other] Program { -brand-name2 } został zaktualizowany.
    }

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

### Localization for Server-side strings of Firefox Screenshots

## Global phrases shared across pages

my-shots = My Shots
home-link = Home
screenshots-description =
    Screenshots made simple. Take, save, and
    share screenshots without leaving Firefox.

## Creating page

# Note: { $title } is a placeholder for the title of the web page
# captured in the screenshot. The default, for pages without titles, is
# creating-page-title-default.
creating-page-title = Creating { $title }
creating-page-title-default = page
creating-page-wait-message = Saving your shot…

emails1 = You have { $unreadEmails } unread emails.
emails2 = You have { NUMBER($unreadEmails) } unread emails.

last-notice =
    Last checked: { DATETIME($lastChecked, day: "numeric", month: "long") }.

today-is = Today is { DATETIME($date) }

dpi-ratio = Your DPI ratio is { NUMBER($ratio, minimumFractionDigits: 2) }

today-is2 = Today is { DATETIME($date, month: "long", year: "numeric", day: "numeric") }

emails3 = Number of unread emails { $unreadEmails }

emails4 = Number of unread emails { NUMBER($undeadEmails) }

liked-count = { $num ->
        [0]     No likes yet.
        [one]   One person liked your message
       *[other] { $num } people liked your message
    }

liked-count2 = { NUMBER($num) ->
        [0]     No likes yet.
        [one]   One person liked your message
       *[other] { $num } people liked your message
    }

log-time = Entry time: { $date }

log-time2 = Entry time: { DATETIME($date) }

today = Today is { $day }

today2 = Today is { DATETIME($day, weekday: "short") }

