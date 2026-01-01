from python import Python
from mojofix.message import FixMessage
from mojofix.experimental.hft.template_parser import TemplateParser
from mojofix.experimental.hft.market_data_parser import MarketDataParser


fn generate_md_snapshot() -> String:
    # MarketDataSnapshot (~1.5KB) with Repeating Groups
    var msg = FixMessage()
    msg.append_pair(8, "FIXT.1.1")
    msg.append_pair(35, "W")
    msg.append_pair(49, "MARKETDATA")
    msg.append_pair(56, "CLIENT")
    msg.append_pair(34, "1000")
    msg.append_pair(52, "20250101-12:00:00.000")
    msg.append_pair(262, "SNAPSHOT_REQ_ID")
    msg.append_pair(268, "20")  # 20 entries of MDEntries

    for i in range(10):
        # Bid
        msg.append_pair(269, "0")
        msg.append_pair(270, "145.50")
        msg.append_pair(271, "100")
        msg.append_pair(273, "12:00:00.000")
        # TemplateParser expects 269, 270, 271, 273 in order for optimal path

        # Offer
        msg.append_pair(269, "1")
        msg.append_pair(270, "145.55")
        msg.append_pair(271, "100")
        msg.append_pair(273, "12:00:00.000")

    return msg.encode()


fn main() raises:
    print("=" * 70)
    print("MOJOFIX: MD TEMPLATE & MARKET DATA PARSER BENCHMARK")
    print("=" * 70)

    var time_module = Python.import_module("time")
    var iterations = 50_000
    var msg = generate_md_snapshot()
    print("Message Length:", len(msg))
    print("Iterations:", iterations)

    # ---------------------------------------------------------
    # MarketDataParser (Fixed Arrays)
    # ---------------------------------------------------------
    print("\n" + "-" * 70)
    print("MarketDataParser (Fixed Arrays)")
    print("-" * 70)

    var md_parser = MarketDataParser()
    # Warmup
    _ = md_parser.parse_incremental(msg)

    var t0 = time_module.time()
    for _ in range(iterations):
        _ = md_parser.parse_incremental(msg)
    var t1 = time_module.time()

    var md_time = t1 - t0
    var md_throughput = iterations / md_time
    var md_latency = (md_time / iterations) * 1_000_000

    print("Throughput:", Int(md_throughput), "msg/s")
    print("Latency:   ", md_latency, "μs")

    # ---------------------------------------------------------
    # TemplateParser (Compile-time Template)
    # ---------------------------------------------------------
    print("\n" + "-" * 70)
    print("TemplateParser (Compile-time Template)")
    print("-" * 70)

    var tmpl_parser = TemplateParser()
    # Warmup
    _ = tmpl_parser.parse_template(msg)

    var t0_tmpl = time_module.time()
    for _ in range(iterations):
        _ = tmpl_parser.parse_template(msg)
    var t1_tmpl = time_module.time()

    var tmpl_time = t1_tmpl - t0_tmpl
    var tmpl_throughput = iterations / tmpl_time
    var tmpl_latency = (tmpl_time / iterations) * 1_000_000

    print("Throughput:", Int(tmpl_throughput), "msg/s")
    print("Latency:   ", tmpl_latency, "μs")

    print("\n" + "=" * 70)
    print("RESULTS")
    print("=" * 70)
    print("MarketDataParser: ", Int(md_throughput), "msg/s")
    print("TemplateParser:   ", Int(tmpl_throughput), "msg/s")
    if md_throughput > 0:
        print("Speedup:          ", tmpl_throughput / md_throughput, "x")
