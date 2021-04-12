import 'package:intl/intl.dart';

/// The `FluentValue` class is the base of Fluent's type system.
///
/// Fluent types wrap Dart values and store additional configuration for
/// them, which can then be used in the `toString` method.
class FluentValue<T> {
  // The wrapped native value.
  T value;

  FluentValue(this.value);

  // Format this instance of `FluentValue` to a string.
  String toString() {
    throw UnimplementedError("Subclasses of FluentValue must implement toString().");
  }
}

/// A `FluentValue` representing no correct value.
class FluentNone extends FluentValue<String> {
  FluentNone([String value = "???"]) : super(value);

  // Format this `FluentNone` to the fallback string.
  String toString() {
    return "{${this.value}}";
  }
}

/// A `FluentValue` representing string value.
class FluentString extends FluentValue<String> {
  FluentString(String value) : super(value);

  // Format this `FluentString` to string.
  String toString() {
    return value;
  }
}

/// A `FluentValue` representing a number.
class FluentNumber extends FluentValue<num> {
  final String? locale;
  final String? style;
  final String? currency;
  // final  String currencyDisplay;
  final bool useGrouping;
  final int? minimumIntegerDigits;
  final int? minimumFractionDigits;
  final int? maximumFractionDigits;
  // final int minimumSignificantDigits;
  // final int maximumSignificantDigits;

  FluentNumber(
    num value, {
    this.locale,
    this.style,
    this.currency,
    // this.currencyDisplay,
    this.useGrouping = true,
    this.minimumIntegerDigits,
    this.minimumFractionDigits,
    this.maximumFractionDigits,
    // this.minimumSignificantDigits,
    // this.maximumSignificantDigits,
  }) : super(value);

  // Format this `FluentNumber` to a string.
  String toString() {
    NumberFormat nf;
    switch (style) {
      case "decimal":
        nf = NumberFormat.decimalPattern(locale);
        break;
      case "currency":
        nf = NumberFormat.currency(locale: locale, name: currency, symbol: currency);
        break;
      case "percent":
        nf = NumberFormat.percentPattern(locale);
        break;
      case "unit":
      default:
        nf = NumberFormat.decimalPattern(locale);
        break;
    }
    if (!useGrouping) {
      nf.turnOffGrouping();
    }
    nf.minimumIntegerDigits = minimumIntegerDigits ?? nf.minimumIntegerDigits;
    nf.minimumFractionDigits = minimumFractionDigits ?? nf.minimumFractionDigits;
    nf.maximumFractionDigits = maximumFractionDigits ?? nf.maximumFractionDigits;

    return nf.format(value);
  }
}

/// A `FluentType` representing a date and time.
class FluentDateTime extends FluentValue<DateTime> {
  String? locale;
  String? pattern;
  String? calendar;
  String? numberingSystem;
  String? timeZone;
  bool hour12;
  String? weekday;
  String? era;
  String? year;
  String? month;
  String? day;
  String? hour;
  String? minute;
  String? second;
  String? timeZoneName;
  FluentDateTime(
    DateTime value, {
    this.locale,
    this.pattern,
    this.calendar,
    this.numberingSystem,
    this.timeZone,
    this.hour12 = false,
    this.weekday,
    this.era,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.timeZoneName,
  }) : super(value);

  // Format this `FluentDateTime` to a string.
  String toString() {
    DateFormat df = DateFormat(pattern, locale);
    return df.format(value);
  }
}
