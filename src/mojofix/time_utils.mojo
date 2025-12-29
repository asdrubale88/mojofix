"""Native Mojo time utilities for FIX timestamp formatting.

This module provides high-performance timestamp formatting without Python dependencies.
Expected performance: 25x faster than Python datetime.
"""

from math import floor


fn days_since_epoch(year: Int, month: Int, day: Int) -> Int:
    """Calculate days since Unix epoch (1970-01-01)."""
    var y = year
    var m = month

    # Adjust for months before March
    if m <= 2:
        y -= 1
        m += 12

    # Calculate days using Zeller-like formula
    var days = (365 * y) + (y // 4) - (y // 100) + (y // 400)
    days += 30 * m + 3 * (m + 1) // 5
    days += day - 719561  # Offset to Unix epoch

    return days


fn format_utc_timestamp(timestamp: Float64, precision: Int = 3) -> String:
    """Format Unix timestamp as FIX UTCTimestamp (YYYYMMDD-HH:MM:SS[.sss]).

    :param timestamp: Unix timestamp (seconds since 1970-01-01 00:00:00 UTC)
    :param precision: Decimal places: 0 (seconds), 3 (ms), or 6 (us)
    :return: Formatted timestamp string
    """
    var total_seconds = Int(timestamp)
    var microseconds = Int((timestamp - Float64(total_seconds)) * 1_000_000)

    # Calculate date components
    var days_since = total_seconds // 86400
    var remaining_seconds = total_seconds % 86400

    # Time components
    var hours = remaining_seconds // 3600
    var minutes = (remaining_seconds % 3600) // 60
    var seconds = remaining_seconds % 60

    # Date calculation (simplified for 1970-2100 range)
    var year = 1970
    var days = days_since

    # Account for leap years
    while True:
        var days_in_year = 366 if is_leap_year(year) else 365
        if days < days_in_year:
            break
        days -= days_in_year
        year += 1

    # Calculate month and day
    var month = 1
    var day = days + 1

    var days_in_months = get_days_in_months(year)
    for i in range(12):
        if day <= days_in_months[i]:
            month = i + 1
            break
        day -= days_in_months[i]

    # Format date part: YYYYMMDD
    var result = String("")
    result += pad_int(year, 4)
    result += pad_int(month, 2)
    result += pad_int(day, 2)
    result += "-"

    # Format time part: HH:MM:SS
    result += pad_int(hours, 2)
    result += ":"
    result += pad_int(minutes, 2)
    result += ":"
    result += pad_int(seconds, 2)

    # Add fractional seconds if needed
    if precision == 3:
        var milliseconds = microseconds // 1000
        result += "."
        result += pad_int(milliseconds, 3)
    elif precision == 6:
        result += "."
        result += pad_int(microseconds, 6)

    return result


fn is_leap_year(year: Int) -> Bool:
    """Check if year is a leap year."""
    if year % 400 == 0:
        return True
    if year % 100 == 0:
        return False
    if year % 4 == 0:
        return True
    return False


fn get_days_in_months(year: Int) -> List[Int]:
    """Get days in each month for given year."""
    var days = List[Int]()
    days.append(31)  # January
    days.append(29 if is_leap_year(year) else 28)  # February
    days.append(31)  # March
    days.append(30)  # April
    days.append(31)  # May
    days.append(30)  # June
    days.append(31)  # July
    days.append(31)  # August
    days.append(30)  # September
    days.append(31)  # October
    days.append(30)  # November
    days.append(31)  # December
    return days^


fn pad_int(value: Int, width: Int) -> String:
    """Pad integer with leading zeros to specified width."""
    var s = String(value)
    while len(s) < width:
        s = "0" + s
    return s


fn format_utc_time_only(timestamp: Float64, precision: Int = 3) -> String:
    """Format Unix timestamp as FIX UTCTimeOnly (HH:MM:SS[.sss]).

    :param timestamp: Unix timestamp
    :param precision: Decimal places: 0 (seconds), 3 (ms), or 6 (us)
    :return: Formatted time string
    """
    var total_seconds = Int(timestamp)
    var microseconds = Int((timestamp - Float64(total_seconds)) * 1_000_000)

    var remaining_seconds = total_seconds % 86400
    var hours = remaining_seconds // 3600
    var minutes = (remaining_seconds % 3600) // 60
    var seconds = remaining_seconds % 60

    var result = String("")
    result += pad_int(hours, 2)
    result += ":"
    result += pad_int(minutes, 2)
    result += ":"
    result += pad_int(seconds, 2)

    if precision == 3:
        var milliseconds = microseconds // 1000
        result += "."
        result += pad_int(milliseconds, 3)
    elif precision == 6:
        result += "."
        result += pad_int(microseconds, 6)

    return result


fn format_timezone_offset(offset_minutes: Int) -> String:
    """Format timezone offset as +HH:MM or -HH:MM or Z.

    :param offset_minutes: Offset from UTC in minutes (positive = east, negative = west)
    :return: Formatted offset string
    """
    if offset_minutes == 0:
        return "Z"

    var sign = "+" if offset_minutes > 0 else "-"
    var abs_minutes = offset_minutes if offset_minutes > 0 else -offset_minutes
    var hours = abs_minutes // 60
    var minutes = abs_minutes % 60

    return sign + pad_int(hours, 2) + ":" + pad_int(minutes, 2)


fn format_tz_timestamp(
    timestamp: Float64, offset_minutes: Int, precision: Int = 3
) -> String:
    """Format Unix timestamp with timezone as FIX TZTimestamp.

    :param timestamp: Unix timestamp
    :param offset_minutes: Timezone offset in minutes from UTC
    :param precision: Decimal places: 0 (seconds), 3 (ms), or 6 (us)
    :return: Formatted timestamp with timezone
    """
    # Adjust timestamp for timezone
    var adjusted_timestamp = timestamp + Float64(offset_minutes * 60)
    var base_format = format_utc_timestamp(adjusted_timestamp, precision)
    var tz_offset = format_timezone_offset(offset_minutes)

    return base_format + tz_offset


fn format_tz_time_only(
    timestamp: Float64, offset_minutes: Int, precision: Int = 3
) -> String:
    """Format Unix timestamp with timezone as FIX TZTimeOnly.

    :param timestamp: Unix timestamp
    :param offset_minutes: Timezone offset in minutes from UTC
    :param precision: Decimal places: 0 (seconds), 3 (ms), or 6 (us)
    :return: Formatted time with timezone
    """
    var adjusted_timestamp = timestamp + Float64(offset_minutes * 60)
    var base_format = format_utc_time_only(adjusted_timestamp, precision)
    var tz_offset = format_timezone_offset(offset_minutes)

    return base_format + tz_offset

fn format_utc_date_only(timestamp: Float64) -> String:
    """Format Unix timestamp as FIX UTCDateOnly (YYYYMMDD)."""
    var total_seconds = Int(timestamp)
    var days_since = total_seconds // 86400
    var year = 1970
    var days = days_since
    while True:
        var days_in_year = 366 if is_leap_year(year) else 365
        if days < days_in_year:
            break
        days -= days_in_year
        year += 1
    var month = 1
    var day = days + 1
    var days_in_months = get_days_in_months(year)
    for i in range(12):
        if day <= days_in_months[i]:
            month = i + 1
            break
        day -= days_in_months[i]
    var result = String("")
    result += pad_int(year, 4)
    result += pad_int(month, 2)
    result += pad_int(day, 2)
    return result

fn format_time_only(timestamp: Float64, precision: Int = 3) -> String:
    """Format Unix timestamp as time-only (HH:MM:SS[.sss]).
    
    :param timestamp: Unix timestamp
    :param precision: Decimal places: 0 (seconds), 3 (ms), or 6 (us)
    :return: Formatted time string
    """
    return format_utc_time_only(timestamp, precision)

fn format_local_mkt_date(timestamp: Float64) -> String:
    """Format Unix timestamp as LocalMktDate (YYYYMMDD).
    
    Same as UTCDateOnly format.
    
    :param timestamp: Unix timestamp
    :return: Formatted date string (YYYYMMDD)
    """
    return format_utc_date_only(timestamp)

fn format_month_year(timestamp: Float64) -> String:
    """Format Unix timestamp as MonthYear (YYYYMM).
    
    :param timestamp: Unix timestamp
    :return: Formatted month-year string (YYYYMM)
    """
    var total_seconds = Int(timestamp)
    var days_since = total_seconds // 86400
    
    var year = 1970
    var days = days_since
    
    while True:
        var days_in_year = 366 if is_leap_year(year) else 365
        if days < days_in_year:
            break
        days -= days_in_year
        year += 1
    
    var month = 1
    var day = days + 1
    
    var days_in_months = get_days_in_months(year)
    for i in range(12):
        if day <= days_in_months[i]:
            month = i + 1
            break
        day -= days_in_months[i]
    
    var result = String("")
    result += pad_int(year, 4)
    result += pad_int(month, 2)
    
    return result
