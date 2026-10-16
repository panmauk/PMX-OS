#!/usr/bin/env bash
set -uo pipefail
cd "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
ISO="$(ls -t *.iso 2>/dev/null | head -1)"
if [ -z "${ISO:-}" ]; then echo "NO ISO FOUND"; exit 1; fi
echo "== ISO =="
ls -lh "$ISO"
echo "size bytes: $(stat -c%s "$ISO")"
echo "== file type =="
file "$ISO"
echo "== El Torito / UEFI boot catalog (xorriso report) =="
xorriso -indev "$ISO" -report_el_torito as_mkisofs 2>/dev/null | grep -iE 'eltorito|efi|isolinux|boot' | head -20 || true
echo "== look for EFI boot image inside =="
xorriso -indev "$ISO" -find /EFI 2>/dev/null | head -20 || echo "  (no /EFI listing via -find)"
echo "INSPECT DONE"
