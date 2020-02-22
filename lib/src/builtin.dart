

import 'package:intl/intl.dart';

String NUMBER(num number, {
    String locale,
    String style,
    String currency,
    // String currencyDisplay,
    bool useGrouping,
    int minimumIntegerDigits,
    int minimumFractionDigits,
    int maximumFractionDigits,
    // int minimumSignificantDigits,
    // int maximumSignificantDigits,
}) {
    NumberFormat nf;
    switch(style) {
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
    if(useGrouping==false) {
        nf.turnOffGrouping();
    }
    nf.minimumIntegerDigits = minimumIntegerDigits ?? nf.minimumIntegerDigits;
    nf.minimumFractionDigits = minimumFractionDigits ?? nf.minimumFractionDigits;
    nf.maximumFractionDigits = maximumFractionDigits ?? nf.maximumFractionDigits;

    return nf.format(number);
}

String DATETIME(DateTime datetime, {
    String locale,
    String pattern,
    String calendar,
    String numberingSystem,
    String timeZone,
    bool hour12,
    String weekday,
    String era,
    String year,
    String month,
    String day,
    String hour,
    String minute,
    String second,
    String timeZoneName,
}) {
    DateFormat df = DateFormat(pattern, locale);
    return df.format(datetime);
}