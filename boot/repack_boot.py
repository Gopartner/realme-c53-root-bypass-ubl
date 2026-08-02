import struct
import hashlib
import lz4.block
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lz4lib import lz4_decompress

BOOT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BOOT_DIR)

STOCK_BOOT = os.path.join(BOOT_DIR, 'stock_boot.img')
PATCHED_CPIO = os.path.join(ROOT, 'ramdisk_patched.cpio')
VBMETA_SRC = os.path.join(BOOT_DIR, 'magisk_patched_boot_fixed.img')
OUT_BOOT = os.path.join(BOOT_DIR, 'magisk_patched_boot_vendorbool.img')

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
        end_hdr = (pos + 110 + namesize + 3) & ~3
        fdata = data[end_hdr:end_hdr + filesize]
        end = (end_hdr + filesize + 3) & ~3
        name = data[pos + 110:pos + 110 + namesize - 1]
        entries.append((hdr, name, fdata))
        if name == b'TRAILER!!!':
            break
        pos = end
    return entries


def rebuild_cpio(entries):
    out = bytearray()
    for i, (hdr, name, fdata) in enumerate(entries):
        if name == b'.backup/.magisk':
            hdr = bytearray(hdr)
            hdr[54:62] = b'%08x' % len(fdata)
            hdr = bytes(hdr)
        hdrb = bytes(hdr)
        namesize = int(hdrb[94:102], 16)
        filesize = int(hdrb[54:62], 16)
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
    return region, len(blocks)


def parse_vbmeta(data):
    footer = data[-64:]
    if footer[:4] != b'AVBf':
        raise ValueError('no AVBf footer')
    vb_offset = struct.unpack('>I', footer[16:20])[0]
    assert data[vb_offset:vb_offset + 4] == b'AVB0'
    # compute actual vbmeta structure end from hash descriptor
    desc = vb_offset + 832
    body = desc + 12
    name_len = struct.unpack('>I', data[body + 44:body + 48])[0]
    salt_len = struct.unpack('>I', data[body + 48:body + 52])[0]
    digest_len = struct.unpack('>I', data[body + 52:body + 56])[0]
    p = body + 120 + name_len + salt_len
    vb_end = (p + digest_len + 7) & ~7
    return vb_offset, vb_end - vb_offset


def main():
    stock = open(STOCK_BOOT, 'rb').read()
    cpio_src = open(PATCHED_CPIO, 'rb').read()
    vb_src = open(VBMETA_SRC, 'rb').read()

    # 1. parse cpio, modify .backup/.magisk
    entries = parse_cpio(cpio_src)
    modified = False
    for i, (hdr, name, fdata) in enumerate(entries):
        if name == b'.backup/.magisk':
            text = fdata.decode('ascii')
            new_text = text.replace('VENDORBOOT=false', 'VENDORBOOT=true')
            if new_text == text:
                raise ValueError('.magisk VENDORBOOT not found')
            entries[i] = (hdr, name, new_text.encode('ascii'))
            modified = True
            print('.magisk updated:')
            print(new_text)
    if not modified:
        raise ValueError('.backup/.magisk not found')
    new_cpio = rebuild_cpio(entries)
    print('new cpio size: %d (was %d)' % (len(new_cpio), len(cpio_src)))

    # 2. verify the new cpio parses and .magisk flag set
    check = parse_cpio(new_cpio)
    for hdr, name, fdata in check:
        if name == b'.backup/.magisk':
            assert b'VENDORBOOT=true' in fdata
    print('cpio round-trip OK (%d entries)' % len(check))

    # 3. compress ramdisk
    region, blen = compress_lz4(new_cpio)
    ram_sz = len(region)
    print('lz4 blocks: %d, region: %d (header ramdisk_size)' % (blen, ram_sz))

    # 4. build boot image
    kernel_size = struct.unpack('<I', stock[8:12])[0]
    header = bytearray(stock[0:4096])
    struct.pack_into('<I', header, 12, ram_sz)
    ramdisk_start = (4096 + kernel_size + 4095) & ~4095

    img = bytearray()
    img += bytes(header)
    img += stock[4096:4096 + kernel_size]
    img += b'\x00' * (ramdisk_start - (4096 + kernel_size))
    img += region
    img += b'\x00' * ((4096 - (len(img) % 4096)) % 4096)
    vb_offset_new = len(img)
    vb_offset_old, vb_size = parse_vbmeta(vb_src)
    vb_block = vb_src[vb_offset_old:vb_offset_old + vb_size]
    img += vb_block
    # pad to partition size minus footer
    img += b'\x00' * (PART_SIZE - 64 - len(img))
    footer = bytearray(vb_src[-64:])
    struct.pack_into('>I', footer, 16, vb_offset_new)
    img += footer
    assert len(img) == PART_SIZE

    # 5. fix vbmeta digest + image_size
    desc = vb_offset_new + 832
    body = desc + 12
    salt_len = struct.unpack('>I', bytes(img[body + 48:body + 52]))[0]
    digest_len = struct.unpack('>I', bytes(img[body + 52:body + 56]))[0]
    name_len = struct.unpack('>I', bytes(img[body + 44:body + 48]))[0]
    p = body + 120 + name_len
    salt = bytes(img[p:p + salt_len])
    digest_offset = p + salt_len
    assert len(salt) == 32
    new_digest = hashlib.sha256(salt + bytes(img[0:vb_offset_new])).digest()
    struct.pack_into('>Q', img, desc + 12 + 4, vb_offset_new)
    img[digest_offset:digest_offset + digest_len] = new_digest

    open(OUT_BOOT, 'wb').write(img)
    print('written: %s' % OUT_BOOT)
    print('vbmeta embedded @ 0x%x size %d' % (vb_offset_new, vb_size))

    # 6. verification: decompress ramdisk from built image, compare cpio
    region2 = bytes(img[ramdisk_start:ramdisk_start + ram_sz])
    assert region2[:4] == MAGIC
    out, _ = lz4_decompress(region2[8:8 + ram_sz])
    assert out == new_cpio, 'ramdisk decompress mismatch'
    print('ramdisk round-trip verified (%d bytes)' % len(out))

    # verify digest now valid
    calc = hashlib.sha256(salt + bytes(img[0:vb_offset_new])).digest()
    stored = bytes(img[digest_offset:digest_offset + digest_len])
    print('digest valid:', calc == stored)


if __name__ == '__main__':
    sys.exit(main())
