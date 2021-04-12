import 'types.dart';

FluentValue NUMBER(
  num number, {
  String? locale,
  String? style,
  String? currency,
  // String currencyDisplay,
  bool useGrouping = true,
  int? minimumIntegerDigits,
  int? minimumFractionDigits,
  int? maximumFractionDigits,
  // int minimumSignificantDigits,
  // int maximumSignificantDigits,
}) {
  return FluentNumber(
    number,
    locale: locale,
    style: style,
    currency: currency,
    useGrouping: useGrouping,
    minimumIntegerDigits: minimumIntegerDigits,
    minimumFractionDigits: minimumFractionDigits,
    maximumFractionDigits: maximumFractionDigits,
  );
}

FluentValue DATETIME(
  DateTime datetime, {
  String? locale,
  String? pattern,
  String? calendar,
  String? numberingSystem,
  String? timeZone,
  bool hour12 = false,
  String? weekday,
  String? era,
  String? year,
  String? month,
  String? day,
  String? hour,
  String? minute,
  String? second,
  String? timeZoneName,
}) {
  return FluentDateTime(
    datetime,
    locale: locale,
    pattern: pattern,
    calendar: calendar,
    numberingSystem: numberingSystem,
    timeZone: timeZone,
    hour12: hour12,
    weekday: weekday,
    era: era,
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
    second: second,
    timeZoneName: timeZoneName,
  );
}
