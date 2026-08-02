def lz4_decompress(src, max_out=64 * 1024 * 1024):
    """Pure-python LZ4 raw block stream decoder (magiskboot lz4_legacy payload).
    Returns (out_bytes, consumed) or raises on invalid data.
    Stops at end-of-stream marker (token 0x00 followed by offset 0x0000)."""
    out = bytearray()
    pos = 0
    n = len(src)
    while pos < n:
        if len(out) > max_out:
            raise ValueError('output too large')
        token = src[pos]
        pos += 1
        litlen = token >> 4
        if litlen == 0xF:
            while pos < n:
                b = src[pos]; pos += 1
                litlen += b
                if b != 0xFF:
                    break
        # copy literals
        if pos + litlen > n:
            raise ValueError('literal overrun')
        out += src[pos:pos + litlen]
        pos += litlen
        if pos + 2 > n:
            # block ends after literals (valid LZ4: last sequence has no match)
            return bytes(out), pos
        offset = src[pos] | (src[pos + 1] << 8)
        if offset == 0:
            return bytes(out), pos + 2
        pos += 2
        mlen_code = token & 0xF
        mlen = mlen_code + 4
        if mlen_code == 0xF:
            while pos < n:
                b = src[pos]; pos += 1
                mlen += b
                if b != 0xFF:
                    break
        if offset > len(out):
            raise ValueError('offset beyond output: off=%d have=%d' % (offset, len(out)))
        # overlapping copy, byte by byte
        start = len(out) - offset
        for i in range(mlen):
            out.append(out[start + i])
    return bytes(out), pos
