import sys
import os

sys.path.insert(0, os.path.join('root-work', 'boot'))
import build_boot as bb


def build_variant(name, modify_magisk, cpio_path='root-work/ramdisk_patched.cpio'):
    src = open(cpio_path, 'rb').read()
    entries = bb.parse_cpio(src)
    changed = False
    for i, (hdr, ename, fdata) in enumerate(entries):
        if ename == b'.backup/.magisk':
            text = fdata.decode('ascii')
            new_text = modify_magisk(text)
            if new_text != text:
                entries[i] = (hdr, ename, new_text.encode('ascii'))
                changed = True
                print(name, '| .magisk ->')
                print(new_text)
    assert changed
    new_cpio = bb.rebuild_cpio(entries)
    # sanity: reparse
    assert len(bb.parse_cpio(new_cpio)) == len(entries)
    vb_src = open(os.path.join('root-work', 'boot', 'magisk_patched_boot_fixed.img'), 'rb').read()
    out = os.path.join('root-work', 'boot', name)
    bb.build_boot(new_cpio, out, vb_src)
    print('built', out)


if __name__ == '__main__':
    build_variant('experiment_B1_meta.img',
                  lambda t: t.replace('PREINITDEVICE=cache', 'PREINITDEVICE=metadata'))
