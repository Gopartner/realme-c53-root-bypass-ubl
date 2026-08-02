import struct
import hashlib
import lz4.block
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lz4lib import lz4_decompress

BOOT_DIR = os.path.dirname(os.path.abspath(__file__))
STOCK_BOOT = os.path.join(BOOT_DIR, 'stock_boot.img')
MAGIC = b'\x02\x21\x4c\x18'
EOS = b'\x00\x00\x00\x00'
PART_SIZE = 67108864


def parse_cpio(data):
    entries = []
    pos = 0
    while pos < len(data):
        hdr = data[pos:pos + 110]
        if hdr[:6] != b'070701':
            raise ValueError('bad cpio magic at %d' % pos)
        namesize = int(hdr[94:102], 16)
        filesize = int(hdr[54:62], 16)
        name = data[pos + 110:pos + 110 + namesize - 1]
        end_hdr = (pos + 110 + namesize + 3) & ~3
        fdata = data[end_hdr:end_hdr + filesize]
        end = (end_hdr + filesize + 3) & ~3
        entries.append((hdr, name, fdata))
        if name == b'TRAILER!!!':
            break
        pos = end
    return entries


def rebuild_cpio(entries):
    out = bytearray()
    for hdr, name, fdata in entries:
        hdrb = bytes(hdr)
        namesize = int(hdrb[94:102], 16)
        filesize = int(hdrb[54:62], 16)
        if len(fdata) != filesize:
            hdrb = bytearray(hdrb)
            hdrb[54:62] = b'%08x' % len(fdata)
            hdrb = bytes(hdrb)
        out += hdrb
        out += name + b'\x00'
        while len(out) % 4 != 0:
            out += b'\x00'
        out += fdata
        while len(out) % 4 != 0:
            out += b'\x00'
    return bytes(out)


def compress_lz4(cpio):
    blocks = lz4.block.compress(cpio, mode='high_compression', store_size=False)
    size_field = len(blocks) + 4
    region = MAGIC + struct.pack('<I', size_field) + blocks + EOS
    return region


def parse_vbmeta(data):
    footer = data[-64:]
    if footer[:4] != b'AVBf':
        raise ValueError('no AVBf footer')
    vb_offset = struct.unpack('>I', footer[16:20])[0]
    assert data[vb_offset:vb_offset + 4] == b'AVB0'
    desc = vb_offset + 832
    body = desc + 12
    name_len = struct.unpack('>I', data[body + 44:body + 48])[0]
    salt_len = struct.unpack('>I', data[body + 48:body + 52])[0]
    digest_len = struct.unpack('>I', data[body + 52:body + 56])[0]
    p = body + 120 + name_len + salt_len
    vb_end = (p + digest_len + 7) & ~7
    return vb_offset, vb_end - vb_offset


def extract_boot(path):
    d = open(path, 'rb').read()
    kernel_size = struct.unpack('<I', d[8:12])[0]
    rsz = struct.unpack('<I', d[12:16])[0]
    ram = (0x1000 + kernel_size + 4095) & ~4095
    region = d[ram:ram + rsz]
    out, _ = lz4_decompress(region[8:8 + rsz])
    return d[0:0x1000], d[0x1000:0x1000 + kernel_size], out, region


def build_boot(cpio, out_path, vbsrc):
    stock = open(STOCK_BOOT, 'rb').read()
    header, kernel, _, _ = extract_boot(STOCK_BOOT)

    region = compress_lz4(cpio)
    ram_sz = len(region)

    header = bytearray(header)
    struct.pack_into('<I', header, 12, ram_sz)
    img = bytearray()
    img += bytes(header)
    img += kernel
    img += b'\x00' * (((4096 - (len(img) % 4096)) % 4096))
    assert len(img) == (4096 + len(kernel) + 4095) & ~4095, len(img)
    img += region
    img += b'\x00' * ((4096 - (len(img) % 4096)) % 4096)
    vb_offset_new = len(img)
    vb_offset_old, vb_size = parse_vbmeta(vbsrc)
    vb_block = vbsrc[vb_offset_old:vb_offset_old + vb_size]
    img += vb_block
    img += b'\x00' * (PART_SIZE - 64 - len(img))
    footer = bytearray(vbsrc[-64:])
    struct.pack_into('>I', footer, 16, vb_offset_new)
    img += footer
    assert len(img) == PART_SIZE

    desc = vb_offset_new + 832
    body = desc + 12
    salt_len = struct.unpack('>I', bytes(img[body + 48:body + 52]))[0]
    digest_len = struct.unpack('>I', bytes(img[body + 52:body + 56]))[0]
    name_len = struct.unpack('>I', bytes(img[body + 44:body + 48]))[0]
    p = body + 120 + name_len
    salt = bytes(img[p:p + salt_len])
    digest_offset = p + salt_len
    new_digest = hashlib.sha256(salt + bytes(img[0:vb_offset_new])).digest()
    struct.pack_into('>Q', img, desc + 12 + 4, vb_offset_new)
    img[digest_offset:digest_offset + digest_len] = new_digest
    open(out_path, 'wb').write(img)

    calc = hashlib.sha256(salt + bytes(img[0:vb_offset_new])).digest()
    stored = bytes(img[digest_offset:digest_offset + digest_len])
    assert calc == stored
    print('digest valid, vbmeta @ %#x' % vb_offset_new)

    region2 = bytes(img[ram_size_check(img):ram_size_check(img) + ram_sz])
    out2, _ = lz4_decompress(region2[8:8 + ram_sz])
    assert out2 == cpio
    print('ramdisk round-trip OK, image: %s (%d bytes)' % (out_path, len(img)))
    return img


def ram_size_check(img):
    ksz = struct.unpack('<I', img[8:12])[0]
    return (0x1000 + ksz + 4095) & ~4095


if __name__ == '__main__':
    vb_src = open(os.path.join(BOOT_DIR, 'magisk_patched_boot_fixed.img'), 'rb').read()
    h, k, stock_cpio, reg = extract_boot(STOCK_BOOT)
    build_boot(stock_cpio, os.path.join(BOOT_DIR, 'experiment_A_reecoded_stock.img'), vb_src)
