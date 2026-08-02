import struct
import hashlib
import sys
import os


def parse_embedded_vbmeta(data):
    footer = data[-64:]
    if footer[:4] != b"AVBf":
        return None
    vb_offset = struct.unpack(">I", footer[16:20])[0]
    vb_size = struct.unpack(">I", footer[24:28])[0]
    if data[vb_offset:vb_offset + 4] != b"AVB0":
        return None
    desc = vb_offset + 832
    body = desc + 12
    image_size = struct.unpack(">Q", data[body + 4:body + 12])[0]
    algo = data[body + 12:body + 44].rstrip(b"\x00").decode("ascii", "replace")
    name_len = struct.unpack(">I", data[body + 44:body + 48])[0]
    salt_len = struct.unpack(">I", data[body + 48:body + 52])[0]
    digest_len = struct.unpack(">I", data[body + 52:body + 56])[0]
    p = body + 120
    name = data[p:p + name_len]
    p += name_len
    salt = data[p:p + salt_len]
    p += salt_len
    digest = data[p:p + digest_len]
    return {
        "vb_offset": vb_offset,
        "vb_size": vb_size,
        "image_size": image_size,
        "algo": algo,
        "name": name,
        "salt": salt,
        "digest": digest,
        "desc_offset": desc,
        "digest_offset": p,
    }


def compute_digest(data, vb_offset, salt):
    if len(salt) != 32:
        raise ValueError("salt length %d != 32" % len(salt))
    return hashlib.sha256(salt + data[0:vb_offset]).digest()


def main():
    if len(sys.argv) < 2:
        print("usage: fix_vbmeta.py <image> [out]")
        return 1
    path = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else path
    data = bytearray(open(path, "rb").read())
    info = parse_embedded_vbmeta(data)
    if info is None:
        print("ERROR: no AVBf footer / AVB0 vbmeta found in %s" % path)
        return 1
    vb = info["vb_offset"]
    calc = compute_digest(data, vb, info["salt"])
    ok = calc == info["digest"]
    print("image        : %s" % path)
    print("vbmeta       : @0x%x (size %d)" % (vb, info["vb_size"]))
    print("image_size   : %d (0x%x)" % (info["image_size"], info["image_size"]))
    print("partition    : %r  algo=%s" % (info["name"], info["algo"]))
    print("salt         : %s" % info["salt"].hex())
    print("stored digest: %s" % info["digest"].hex())
    print("calc digest  : %s" % calc.hex())
    if not ok:
        data[info["digest_offset"]:info["digest_offset"] + 32] = calc
        struct.pack_into(">Q", data, info["desc_offset"] + 12 + 4, vb)
        open(out, "wb").write(data)
        print("FIXED: digest + image_size updated -> %s" % out)
    else:
        print("OK: digest already valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
