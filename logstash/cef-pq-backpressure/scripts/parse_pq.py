import struct, cbor2

PAGE    = "/tmp/pq-page0.bin"
SEQNUM  = 8
LENSIZE = 4
CRC     = 4

with open(PAGE, "rb") as f:
    data = f.read()

version = data[0]
print(f"Page version : {version}")
print(f"File size    : {len(data):,} bytes")
print()

offset = 1  # skip version byte
shown  = 0
total  = 0

while offset + SEQNUM + LENSIZE < len(data):
    seq = struct.unpack_from(">Q", data, offset)[0]
    if seq == 0:
        break
    length = struct.unpack_from(">I", data, offset + SEQNUM)[0]
    if length == 0 or length > 200_000:
        break

    cbor_bytes = data[offset + SEQNUM + LENSIZE : offset + SEQNUM + LENSIZE + length]
    offset += SEQNUM + LENSIZE + length + CRC
    total += 1

    if shown >= 3:
        continue

    try:
        raw = cbor2.loads(cbor_bytes)
        # Logstash serializes as ['java.util.HashMap', {'DATA': ['org.logstash.ConvertedMap', {fields}], ...}]
        data_map = raw[1]['DATA'][1]

        print(f"=== Event seq={seq} ({length} bytes CBOR) ===")
        for k, v in sorted(data_map.items()):
            # unwrap typed values: ['org.jruby.RubyString', actual_value]
            if isinstance(v, list) and len(v) == 2 and isinstance(v[0], str):
                type_tag, v = v[0].split('.')[-1], v[1]
            else:
                type_tag = type(v).__name__

            if isinstance(v, (bytes, bytearray)):
                # show hex of first 20 bytes + TLS record type identification
                tls_type = 'TLS ClientHello' if v[:3] == b'\x16\x03\x01' else 'binary'
                display = f"<{len(v)} bytes {tls_type}>  {v[:20].hex()}"
            elif isinstance(v, list):  # ConvertedList — unwrap tags
                items = [x[1] if isinstance(x, list) and len(x)==2 else x for x in v]
                display = str(items)
            elif isinstance(v, str) and not v.isprintable() and len(v) > 4:
                display = f"<{len(v)} chars binary string>  first bytes: {v[:6].encode().hex()}"
            else:
                display = repr(v)
            print(f"  {k:20s} [{type_tag:20s}] = {display}")
        print()
        shown += 1
    except Exception as e:
        print(f"  parse error at seq={seq}: {e}")
        break

print(f"Total events parsed from binary: {total}")
