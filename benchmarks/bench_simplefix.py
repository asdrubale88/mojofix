
import time
import simplefix

def generate_short():
    msg = simplefix.FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "0")
    msg.append_pair(49, "SENDER")
    msg.append_pair(56, "TARGET")
    msg.append_pair(34, "1")
    msg.append_pair(52, "20250101-12:00:00.000")
    return msg.encode()

def generate_medium():
    msg = simplefix.FixMessage()
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

def generate_long():
    msg = simplefix.FixMessage()
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
    msg.append_pair(268, "20")

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

def run_parser_benchmark(name, msg_raw, iterations):
    print(f"Benchmarking {name}...")
    start = time.time()
    parser = simplefix.FixParser()
    for _ in range(iterations):
        parser.reset()
        parser.append_buffer(msg_raw)
        _ = parser.get_message()
    end = time.time()
    
    duration = end - start
    if duration == 0: duration = 0.000001
    
    msg_sec = iterations / duration
    latency_us = (duration / iterations) * 1_000_000
    
    print(f"| {name:<30} | {int(msg_sec)} msg/s | {latency_us:.2f} μs |")

def run_builder_benchmark(name, iterations, size_type):
    print(f"Benchmarking Builder {name}...")
    start = time.time()
    for _ in range(iterations):
        msg = simplefix.FixMessage()
        if size_type == "short":
            msg.append_pair(8, "FIX.4.2")
            msg.append_pair(35, "0")
            msg.append_pair(49, "SENDER")
            msg.append_pair(56, "TARGET")
            msg.append_pair(34, "1")
            msg.append_pair(52, "20250101-12:00:00.000")
        elif size_type == "medium":
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
        _ = msg.encode()
    end = time.time()
    
    duration = end - start
    if duration == 0: duration = 0.000001
    
    msg_sec = iterations / duration
    latency_us = (duration / iterations) * 1_000_000
    
    print(f"| {name:<30} | {int(msg_sec)} msg/s | {latency_us:.2f} μs |")


if __name__ == "__main__":
    msg_short = generate_short()
    msg_medium = generate_medium()
    msg_long = generate_long()
    
    print(f"Short len: {len(msg_short)}")
    print(f"Medium len: {len(msg_medium)}")
    print(f"Long len: {len(msg_long)}")
    
    print("\n" + "="*60)
    print("SIMPLEFIX PYTHON BENCHMARK")
    print("="*60)
    
    run_parser_benchmark("simplefix Parser (Short)", msg_short, 200000)
    run_parser_benchmark("simplefix Parser (Medium)", msg_medium, 100000)
    run_parser_benchmark("simplefix Parser (Long)", msg_long, 20000)
    
    print("\n" + "-"*60)
    
    run_builder_benchmark("simplefix Builder (Short)", 100000, "short")
    run_builder_benchmark("simplefix Builder (Medium)", 100000, "medium")

