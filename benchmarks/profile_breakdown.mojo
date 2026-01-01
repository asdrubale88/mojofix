from time import perf_counter_ns
from collections import List, Optional
from mojofix.message import FixMessage, FixField, FixTags
from mojofix.parser import FixParser
from mojofix.simd_utils import checksum_hot_path


fn profile_encode(msg: FixMessage, iterations: Int):
    var total_time = 0

    var t_scan = 0
    var t_alloc = 0
    var t_write = 0
    var t_checksum = 0

    var soh_byte = UInt8(1)
    var eq_byte = UInt8(61)

    for _ in range(iterations):
        var t0 = perf_counter_ns()

        # --- PHASE 1: Scan ---
        var f8: Optional[String] = None
        var f35: Optional[String] = None
        var body_len = 0

        for i in range(len(msg.header_fields)):
            var f = msg.header_fields[i].copy()
            if f.tag == FixTags.BEGIN_STRING:
                f8 = f.value
            elif f.tag == FixTags.BODY_LENGTH:
                pass
            elif f.tag == FixTags.CHECKSUM:
                pass
            elif f.tag == FixTags.MSG_TYPE:
                f35 = f.value
                body_len += 4 + len(f.value)
            else:
                # Helper simulation
                var tlen = 5
                if f.tag < 10:
                    tlen = 1
                elif f.tag < 100:
                    tlen = 2
                elif f.tag < 1000:
                    tlen = 3
                elif f.tag < 10000:
                    tlen = 4

                body_len += tlen + 1 + len(f.value) + 1

        for i in range(len(msg.fields)):
            var f = msg.fields[i].copy()
            if f.tag == FixTags.BEGIN_STRING:
                f8 = f.value
            elif f.tag == FixTags.BODY_LENGTH:
                pass
            elif f.tag == FixTags.CHECKSUM:
                pass
            elif f.tag == FixTags.MSG_TYPE:
                f35 = f.value
                body_len += 4 + len(f.value)
            else:
                var tlen = 5
                if f.tag < 10:
                    tlen = 1
                elif f.tag < 100:
                    tlen = 2
                elif f.tag < 1000:
                    tlen = 3
                elif f.tag < 10000:
                    tlen = 4

                body_len += tlen + 1 + len(f.value) + 1

        var t1 = perf_counter_ns()
        t_scan += Int(t1 - t0)

        # --- PHASE 2: Alloc ---
        var buf = List[UInt8]()
        buf.reserve(body_len + 50)

        var t2 = perf_counter_ns()
        t_alloc += Int(t2 - t1)

        # --- PHASE 3: Write ---
        if f8:
            buf.extend(String("8=").as_bytes())
            buf.extend(f8.value().as_bytes())
            buf.append(soh_byte)

        buf.extend(String("9=").as_bytes())
        buf.extend(String(body_len).as_bytes())
        buf.append(soh_byte)

        if f35:
            buf.extend(String("35=").as_bytes())
            buf.extend(f35.value().as_bytes())
            buf.append(soh_byte)

        for i in range(len(msg.header_fields)):
            var f = msg.header_fields[i].copy()
            if (
                f.tag != FixTags.BEGIN_STRING
                and f.tag != FixTags.BODY_LENGTH
                and f.tag != FixTags.CHECKSUM
                and f.tag != FixTags.MSG_TYPE
            ):
                # write_int simulation
                var val = f.tag
                if val < 10:
                    buf.append(UInt8(val + 48))
                elif val < 100:
                    buf.append(UInt8((val // 10) + 48))
                    buf.append(UInt8((val % 10) + 48))
                elif val < 1000:
                    buf.append(UInt8((val // 100) + 48))
                    buf.append(UInt8(((val // 10) % 10) + 48))
                    buf.append(UInt8((val % 10) + 48))
                else:
                    buf.extend(String(val).as_bytes())

                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

        for i in range(len(msg.fields)):
            var f = msg.fields[i].copy()
            if (
                f.tag != FixTags.BEGIN_STRING
                and f.tag != FixTags.BODY_LENGTH
                and f.tag != FixTags.CHECKSUM
                and f.tag != FixTags.MSG_TYPE
            ):
                var val = f.tag
                if val < 10:
                    buf.append(UInt8(val + 48))
                elif val < 100:
                    buf.append(UInt8((val // 10) + 48))
                    buf.append(UInt8((val % 10) + 48))
                elif val < 1000:
                    buf.append(UInt8((val // 100) + 48))
                    buf.append(UInt8(((val // 10) % 10) + 48))
                    buf.append(UInt8((val % 10) + 48))
                else:
                    buf.extend(String(val).as_bytes())

                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

        var out_msg = String(bytes=buf)
        buf.clear()

        var t3 = perf_counter_ns()
        t_write += Int(t3 - t2)

        # --- PHASE 4: Checksum ---
        var csum = checksum_hot_path(out_msg)
        var csum_str = String(csum)
        while len(csum_str) < 3:
            csum_str = String("0") + csum_str
        out_msg += String("10=") + csum_str + String(chr(1))

        var t4 = perf_counter_ns()
        t_checksum += Int(t4 - t3)

    print("ENCODE PROFILE (per msg in ns):")
    print("  Scan:     ", t_scan // iterations)
    print("  Alloc:    ", t_alloc // iterations)
    print("  Write:    ", t_write // iterations)
    print("  Checksum: ", t_checksum // iterations)
    print(
        "  TOTAL:    ", (t_scan + t_alloc + t_write + t_checksum) // iterations
    )


fn profile_parse(raw_msg: String, iterations: Int):
    var t_find_start = 0
    var t_find_body = 0
    var t_extract_body = 0
    var t_parse_fields = 0

    var parser = FixParser()

    for _ in range(iterations):
        var msg_buffer = raw_msg
        var t0 = perf_counter_ns()

        # --- PHASE 1: Find 8= ---
        var start_pos = msg_buffer.find("8=")
        if start_pos == -1:
            continue
        if start_pos > 0:
            pass

        var t1 = perf_counter_ns()
        t_find_start += Int(t1 - t0)

        # --- PHASE 2: Find Body Len ---
        var pattern_9 = String(chr(1)) + "9="
        var pos_9 = msg_buffer.find(pattern_9)
        if pos_9 == -1:
            continue

        var val_start = pos_9 + len(pattern_9)
        var pos_next_soh = msg_buffer.find(String(chr(1)), val_start)
        var body_len_str = String(msg_buffer[val_start:pos_next_soh])

        var body_len = 0
        try:
            body_len = Int(body_len_str)
        except:
            pass

        var t2 = perf_counter_ns()
        t_find_body += Int(t2 - t1)

        # --- PHASE 3: Slice Message ---
        var body_start = pos_next_soh + 1
        var total_end = body_start + body_len + 7
        var raw_slice = String(msg_buffer[:total_end])

        var t3 = perf_counter_ns()
        t_extract_body += Int(t3 - t2)

        # --- PHASE 4: Parse Fields Loop ---
        var msg = FixMessage()
        var point = 0
        var raw = raw_slice

        while point < len(raw):
            var eq_pos = raw.find("=", point)

            if eq_pos == -1:
                break

            # Simulate _parse_tag_fast behavior for benchmark
            var tag = 0
            var ptr = raw.unsafe_ptr() + point
            var len_tag = eq_pos - point
            if len_tag > 0:
                var first = ptr.load(0)
                if first >= 48 and first <= 57:
                    for i in range(len_tag):
                        var c = ptr.load(i)
                        if c >= 48 and c <= 57:
                            tag = tag * 10 + Int(c - 48)

            if tag == 0:
                point += 1
                continue

            var val_start_idx = eq_pos + 1
            var soh_pos = raw.find(String(chr(1)), val_start_idx)
            var value: String
            if soh_pos == -1:
                value = String(raw[val_start_idx:])
                point = len(raw)
            else:
                value = String(raw[val_start_idx:soh_pos])
                point = soh_pos + 1

            msg.append_pair(tag, value)

        var t4 = perf_counter_ns()
        t_parse_fields += Int(t4 - t3)

    print("\nPARSE PROFILE (per msg in ns):")
    print("  Find 8=:      ", t_find_start // iterations)
    print("  Read Len:     ", t_find_body // iterations)
    print("  Extract Body: ", t_extract_body // iterations)
    print("  Parse Fields: ", t_parse_fields // iterations)
    print(
        "  TOTAL:        ",
        (t_find_start + t_find_body + t_extract_body + t_parse_fields)
        // iterations,
    )


fn main():
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2", header=True)
    msg.append_pair(35, "D", header=True)
    msg.append_pair(49, "SENDER", header=True)
    msg.append_pair(56, "TARGET", header=True)
    msg.append_pair(34, "1", header=True)
    msg.append_pair(52, "20240101-12:00:00.000", header=True)

    msg.append_pair(11, "ORDERID123")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")
    msg.append_pair(44, "150.50")
    msg.append_pair(10, "000")  # Checksum place holder

    var raw_msg = msg.encode()
    print("Profiling message of length: ", len(raw_msg))

    print("Warming up...")
    profile_encode(msg, 1000)
    profile_parse(raw_msg, 1000)

    print("Running Profile...")
    profile_encode(msg, 10000)
    profile_parse(raw_msg, 10000)
