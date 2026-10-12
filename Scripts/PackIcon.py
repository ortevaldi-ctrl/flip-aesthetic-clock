"""Encode PNG representations in the documented macOS ICNS container format."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parent.parent
iconset = root / 'Resources' / 'FLIP.iconset'
representations = {
    b'icp4': 'icon_16x16.png', b'icp5': 'icon_32x32.png',
    b'icp6': 'icon_32x32@2x.png', b'ic07': 'icon_128x128.png',
    b'ic08': 'icon_256x256.png', b'ic09': 'icon_512x512.png',
    b'ic10': 'icon_512x512@2x.png', b'ic11': 'icon_16x16@2x.png',
    b'ic12': 'icon_32x32@2x.png', b'ic13': 'icon_128x128@2x.png',
    b'ic14': 'icon_256x256@2x.png',
}
chunks = []
for kind, name in representations.items():
    data = (iconset / name).read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n')
    chunks.append(kind + struct.pack('>I', len(data) + 8) + data)
payload = b''.join(chunks)
(root / 'Resources' / 'FLIP.icns').write_bytes(b'icns' + struct.pack('>I', len(payload) + 8) + payload)
print('FLIP.icns: 11 PNG representations packed')

(root / "Resources" / "FLIP-Terminal.icns").write_bytes((root / "Resources" / "FLIP.icns").read_bytes())
