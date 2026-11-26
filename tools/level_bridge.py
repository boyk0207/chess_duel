"""Level the original segmented suspension bridge while retaining UVs, textures and parts."""
import json
import struct
from pathlib import Path
import numpy as np

arena = Path(__file__).resolve().parents[1] / 'assets' / 'arena'
source = arena / 'Bridge_Segmented.glb'
output = arena / 'Bridge_Walkable.glb'
raw = source.read_bytes()
json_len = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20 + json_len])
binary = bytearray(raw[28 + json_len:])


def array(index):
    a = doc['accessors'][index]
    view = doc['bufferViews'][a['bufferView']]
    return np.frombuffer(binary, '<f4', count=a['count'] * 3,
                         offset=view.get('byteOffset', 0) + a.get('byteOffset', 0)).reshape(-1, 3)


def write(index, values):
    a = doc['accessors'][index]
    arr = array(index)
    arr[:] = values
    a['min'] = arr.min(axis=0).tolist()
    a['max'] = arr.max(axis=0).tolist()


def attrs(node):
    return doc['meshes'][node['mesh']]['primitives'][0]['attributes']

planks = sorted((n for n in doc['nodes'] if n['name'].startswith('Plank_')), key=lambda n: n['name'])
assert len(planks) == 17
profile = []
pitch = 3.30 / len(planks) # 0.15 m overlap on each island; gap between islands is 3 m.
for i, node in enumerate(planks):
    at = attrs(node)
    p = array(at['POSITION']).copy().astype(float)
    normals = array(at['NORMAL']).copy().astype(float)
    old_t = np.array(node['translation'])
    top = p[normals[:, 1] > 0.6]
    slope, intercept = np.linalg.lstsq(np.column_stack((top[:, 0], np.ones(len(top)))), top[:, 1], rcond=None)[0]
    profile.append((old_t[0], old_t[1] + intercept))
    # Rotate the sloping plank until the top face is horizontal.
    angle = -np.arctan(slope)
    c, s = np.cos(angle), np.sin(angle)
    rot = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
    p = p @ rot.T
    normals = normals @ rot.T
    # Keep the wood grain and width, fit the pieces to a consistent pitch.
    p[:, 0] -= (p[:, 0].max() + p[:, 0].min()) / 2
    stretch = (pitch - 0.006) / np.ptp(p[:, 0])
    p[:, 0] *= stretch
    normals[:, 0] /= stretch
    normals /= np.linalg.norm(normals, axis=1, keepdims=True)
    p[:, 1] -= p[:, 1].max()
    write(at['POSITION'], p)
    write(at['NORMAL'], normals)
    node['translation'] = [(i - 8) * pitch, 0.0, float(old_t[2])]

# Remove the deck's former deep sag from the ropes and posts without changing their texture.
profile = np.array(profile)
for node in doc['nodes']:
    if node['name'].startswith('Plank_'):
        continue
    at = attrs(node)
    t = np.array(node['translation'])
    p = array(at['POSITION']).copy().astype(float) + t
    n = array(at['NORMAL']).copy().astype(float)
    x = p[:, 0].copy()
    yoff = np.interp(x, profile[:, 0], profile[:, 1])
    seg = np.clip(np.searchsorted(profile[:, 0], x, side='right') - 1, 0, len(profile)-2)
    slopes = (profile[seg+1, 1]-profile[seg, 1])/(profile[seg+1, 0]-profile[seg, 0])
    slopes[(x < profile[0, 0]) | (x > profile[-1, 0])] = 0
    p[:, 1] -= yoff
    n[:, 0] += slopes*n[:, 1]
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-8)
    center = (p.min(axis=0)+p.max(axis=0))/2
    node['translation'] = center.tolist()
    write(at['POSITION'], p-center)
    write(at['NORMAL'], n)

j = json.dumps(doc, separators=(',', ':')).encode()
j += b' ' * (-len(j) % 4)
binary += b'\0' * (-len(binary) % 4)
output.write_bytes(struct.pack('<4sII', b'glTF', 2, 28+len(j)+len(binary))
                   + struct.pack('<I4s', len(j), b'JSON') + j
                   + struct.pack('<I4s', len(binary), b'BIN\0') + binary)
print(output)
