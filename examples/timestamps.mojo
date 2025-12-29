"""Timestamp handling example for Mojofix.

This example demonstrates:
- Adding UTC timestamps
- Adding timezone-aware timestamps
- Different timestamp formats
"""

from mojofix import FixMessage
from python import Python


fn main() raises:
    print("=" * 60)
    print("Mojofix Timestamp Example")
    print("=" * 60)

    # Get current time using Python
    var time_module = Python.import_module("time")
    var current_time = Float64(time_module.time())

    # Create message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Add UTC timestamp (SendingTime - tag 52)
    print("\nAdding timestamps...")
    msg.append_utc_timestamp(52, current_time, precision=3)
    print("  ✅ UTC timestamp added (tag 52)")

    # Add timezone-aware timestamp (TransactTime - tag 60)
    # Offset: +60 minutes (UTC+1)
    msg.append_tz_timestamp(60, current_time, offset_minutes=60, precision=3)
    print("  ✅ TZ timestamp added (tag 60, UTC+1)")

    # Add date-only field (TradeDate - tag 75)
    msg.append_utc_date_only(75, current_time)
    print("  ✅ Date-only added (tag 75)")

    # Add time-only field (tag 108)
    msg.append_time_only(108, current_time, precision=3)
    print("  ✅ Time-only added (tag 108)")

    # Encode and display
    var encoded = msg.encode()
    print("\nEncoded message:")
    print(encoded)

    # Display individual timestamp fields
    print("\nTimestamp Fields:")
    var sending_time = msg.get(52)
    if sending_time:
        print("  SendingTime (52):", sending_time.value())

    var transact_time = msg.get(60)
    if transact_time:
        print("  TransactTime (60):", transact_time.value())

    var trade_date = msg.get(75)
    if trade_date:
        print("  TradeDate (75):", trade_date.value())

    var time_only = msg.get(108)
    if time_only:
        print("  TimeOnly (108):", time_only.value())

    print("\n" + "=" * 60)
    print("✅ Example completed successfully!")
    print("=" * 60)
