# Fluent

This is a Dart implementation of Project Fluent, a localization framework designed to unleash the entire expressive power of natural language translations.

Project Fluent keeps simple things simple and makes complex things possible. The syntax used for describing translations is easy to read and understand. At the same time it allows, when necessary, to represent complex concepts from natural languages like gender, plurals, conjugations, and others.

## Getting Started

Using fluent.runtime
====================

Learn the FTL syntax
--------------------

FTL is a localization file format used for describing translation
resources. FTL stands for *Fluent Translation List*.

FTL is designed to be simple to read, but at the same time allows to
represent complex concepts from natural languages like gender, plurals,
conjugations, and others.

::

    hello-user = Hello, { $username }!

In order to use fluent.runtime, you will need to create FTL files. `Read the
Fluent Syntax Guide <http://projectfluent.org/fluent/guide/>`_ in order to
learn more about the syntax.

Using FluentBundle
------------------

Once you have some FTL files, you can generate translations using the ``fluent`` package. You start with the ``FluentBundle`` class:

::

    import 'package:fluent/fluent.dart';

You pass a locale to the constructor:

::

    final bundle = FluentBundle('en-US');

You must then add messages. These would normally come from a ``.ftl``
file stored on disk, here we will just add them directly:

::

    bundle.addMessages('''
    welcome = Welcome to this great app!
    greet-by-name = Hello, { $name }!
    ''');

To generate translations, use the ``format`` method, passing a message
ID and an optional dictionary of substitution parameters. If the the
message ID is not found, null is returned. Otherwise, as per
the Fluent philosophy, the implementation tries hard to recover from any
formatting errors and generate the most human readable representation of
the value.

::

	List<Error> errors = [];
    translated = bundle.format('welcome', errors: errors)
    translated = bundle.format('greet-by-name', args: {'name': 'Jane'}, errors: errors)


Known limitations and bugs
--------------------------

- We do not yet support ``NUMBER(..., currencyDisplay="...", minimumSignificantDigits="...", maximumSignificantDigits=".. ")``

- Most options to ``DATETIME`` are not yet supported. See the `MDN docs for
  Intl.DateTimeFormat
  <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat>`_,
  the `ECMA spec for BasicFormatMatcher
  <http://www.ecma-international.org/ecma-402/1.0/#BasicFormatMatcher>`_ and the
  `Intl.js polyfill
  <https://github.com/andyearnshaw/Intl.js/blob/master/src/12.datetimeformat.js>`_.

Help with the above would be welcome!