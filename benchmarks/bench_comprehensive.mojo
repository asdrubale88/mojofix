from python import Python, PythonObject
from mojofix import FixParser, FixMessage
from mojofix.experimental.hft import FastParser, FastMessage


# Helper to format float to string with precision
fn fmt_float(val: Float64) -> String:
    var i_part = Int(val)
    var d_part = Int((val - Float64(i_part)) * 100)
    var s_d = String(d_part)
    if d_part < 10:
        s_d = "0" + s_d
    return String(i_part) + "." + s_d


fn generate_short() -> String:
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "0")
    msg.append_pair(49, "SENDER")
    msg.append_pair(56, "TARGET")
    msg.append_pair(34, "1")
    msg.append_pair(52, "20250101-12:00:00.000")
    return msg.encode()


fn generate_medium() -> String:
    # Execution Report (~300 bytes)
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "8")
    msg.append_pair(49, "SENDER")
    msg.append_pair(56, "TARGET")
    msg.append_pair(34, "100")
    msg.append_pair(52, "20250101-12:00:00.000")

    msg.append_pair(37, "ORDERID123456789")
    msg.append_pair(11, "CLORDID123456789")
    msg.append_pair(17, "EXECID123456789")
    msg.append_pair(150, "0")
    msg.append_pair(39, "0")
    msg.append_pair(55, "MSFT")
    msg.append_pair(54, "1")
    msg.append_pair(38, "1000")
    msg.append_pair(44, "150.50")
    msg.append_pair(32, "0")
    msg.append_pair(31, "0.0")
    msg.append_pair(151, "1000")
    msg.append_pair(14, "0")
    msg.append_pair(6, "150.50")
    msg.append_pair(60, "20250101-12:00:00.000")
    msg.append_pair(58, "FILL ORDER COMPLETED SUCCESSFULLY")

    return msg.encode()


fn generate_long() -> String:
    # MarketDataSnapshot (~1.5KB) with Repeating Groups
    # Note: mojo-fix simple FixMessage doesn't strictly enforce group structure in encode()
    # but generates valid tag=value streams. We'll simulate groups by appending tags sequentially.
    var msg = FixMessage()
    msg.append_pair(8, "FIXT.1.1")
    msg.append_pair(35, "W")
    msg.append_pair(49, "MARKETDATA")
    msg.append_pair(56, "CLIENT")
    msg.append_pair(34, "1000")
    msg.append_pair(52, "20250101-12:00:00.000")

    msg.append_pair(262, "SNAPSHOT_REQ_ID")
    msg.append_pair(55, "NVDA")
    msg.append_pair(48, "US67066G1040")
    msg.append_pair(22, "4")

    msg.append_pair(268, "20")  # 20 entries of MDEntries

    for i in range(10):
        # Bid
        msg.append_pair(269, "0")
        msg.append_pair(270, "145.50")
        msg.append_pair(271, "100")
        msg.append_pair(272, "20250101")
        msg.append_pair(273, "12:00:00.000")
        msg.append_pair(290, "1")
        msg.append_pair(274, "1")
        msg.append_pair(276, "0")
        msg.append_pair(277, "1")
        msg.append_pair(1023, "1")
        msg.append_pair(282, "1")

        # Offer
        msg.append_pair(269, "1")
        msg.append_pair(270, "145.55")
        msg.append_pair(271, "100")
        msg.append_pair(272, "20250101")
        msg.append_pair(273, "12:00:00.000")
        msg.append_pair(290, "1")
        msg.append_pair(274, "1")
        msg.append_pair(276, "0")
        msg.append_pair(277, "1")
        msg.append_pair(1023, "1")
        msg.append_pair(282, "1")

    return msg.encode()


fn run_benchmark(
    name: String,
    msg: String,
    iterations: Int,
    time_module: PythonObject,
    run_fast: Bool,
) raises -> String:
    print("Benchmarking " + name + "...")

    var start_time: Float64 = 0.0
    var end_time: Float64 = 0.0
    var total_valid: Int = 0

    if run_fast:
        var parser = FastParser()
        var reusable_msg = FastMessage("")

        # Check correctness once
        parser.parse_into(msg, reusable_msg)
        if reusable_msg.get(35) == "":
            print("ERROR: HFT Parser failed to parse message!")

        start_time = Float64(time_module.time())
        for _ in range(iterations):
            parser.parse_into(msg, reusable_msg)
            _ = reusable_msg.get(35)
        end_time = Float64(time_module.time())
        total_valid = iterations

    else:
        var parser = FixParser()

        # Check correctness once
        parser.append_buffer(msg)
        var m_check = parser.get_message()
        if not m_check:
            print(
                "ERROR: Safe Parser failed to parse message! Invalid BodyLength"
                " or Checksum?"
            )
        else:
            _ = m_check.value().get(35)

        start_time = Float64(time_module.time())
        for _ in range(iterations):
            var local_parser = FixParser()
            local_parser.append_buffer(msg)
            var m = local_parser.get_message()
            if m:
                _ = m.value().get(35)
                total_valid += 1
        end_time = Float64(time_module.time())

    if total_valid < iterations:
        print(
            "WARNING: Only "
            + String(total_valid)
            + "/"
            + String(iterations)
            + " messages passed validation."
        )

    var duration = end_time - start_time
    if duration == 0:
        duration = 0.000001

    var msg_sec = Float64(iterations) / duration
    var latency_us = (duration / Float64(iterations)) * 1_000_000

    var ms_str = String(Int(msg_sec))
    var lat_str = fmt_float(latency_us)

    var padded_name = name
    while len(padded_name) < 30:
        padded_name += " "

    return "| " + padded_name + " | " + ms_str + " msg/s | " + lat_str + " μs |"


fn main() raises:
    print("Initializing Benchmark Suite...")
    var time_module = Python.import_module("time")

    # Generate valid messages
    var msg_short = generate_short()
    var msg_medium = generate_medium()
    var msg_long = generate_long()

    print("Messages generated.")
    print("Short len: " + String(len(msg_short)))
    print("Medium len: " + String(len(msg_medium)))
    print("Long len: " + String(len(msg_long)))

    # ---------------------------------------------------------
    # Run Benchmarks
    # ---------------------------------------------------------

    print("\n" + "=" * 65)
    print("COMPREHENSIVE MOJOFIX BENCHMARK")
    print("=" * 65 + "\n")

    var results = List[String]()

    # Short (reduce iterations for Safe parser if unsafe is invalid, but here we assume safe)
    results.append(
        run_benchmark(
            "Safe Parser (Short 60B)", msg_short, 200_000, time_module, False
        )
    )
    results.append(
        run_benchmark(
            "HFT Parser  (Short 60B)", msg_short, 200_000, time_module, True
        )
    )

    # Medium
    results.append(
        run_benchmark(
            "Safe Parser (Medium 310B)", msg_medium, 100_000, time_module, False
        )
    )
    results.append(
        run_benchmark(
            "HFT Parser  (Medium 310B)", msg_medium, 100_000, time_module, True
        )
    )

    # Long
    results.append(
        run_benchmark(
            "Safe Parser (Long 1.6KB)", msg_long, 20_000, time_module, False
        )
    )
    results.append(
        run_benchmark(
            "HFT Parser  (Long 1.6KB)", msg_long, 20_000, time_module, True
        )
    )

    # ---------------------------------------------------------
    # Print Table
    # ---------------------------------------------------------
    print("\n" + "=" * 65)
    print("FINAL RESULTS")
    print("=" * 65)
    print("| Benchmark                      | Throughput    | Latency   |")
    print("| :----------------------------- | :------------ | :-------- |")

    for i in range(len(results)):
        print(results[i])

    print("\nDetails:")
    print("- Short:  FIX 4.2 Heartbeat")
    print("- Medium: FIX 4.4 ExecutionReport")
    print("- Long:   FIX 5.0 MarketDataSnapshot (Repeating Groups)")
