"""Build a walkable sagging suspension bridge from the original levelled pieces."""
from pathlib import Path
import json, struct
import numpy as np
arena=Path(__file__).resolve().parents[1]/'assets'/'arena'
raw=(arena/'Bridge_Walkable.glb').read_bytes()
n=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+n]); binary=bytearray(raw[28+n:])
pitch=3.3/17
boundaries=np.arange(18)*pitch-1.65
t=np.clip((np.arange(18)-1)/15,0,1)
heights=-.42*4*t*(1-t)
slopes=np.diff(heights)/pitch

def array(index):
 a=doc['accessors'][index]; v=doc['bufferViews'][a['bufferView']]
 return np.frombuffer(binary,'<f4',count=a['count']*3,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,3)
def write(index, values):
 a=doc['accessors'][index]; arr=array(index); arr[:]=values
 a['min']=arr.min(0).tolist();a['max']=arr.max(0).tolist()

for node in doc['nodes']:
 attrs=doc['meshes'][node['mesh']]['primitives'][0]['attributes']
 p=array(attrs['POSITION']).copy().astype(float); norm=array(attrs['NORMAL']).copy().astype(float)
 tr=np.array(node['translation'],dtype=float)
 if node['name'].startswith('Plank_'):
  i=int(node['name'].split('_')[1]); slope=slopes[i]
  p[:,1]+=slope*p[:,0]; norm[:,0]-=slope*norm[:,1]
  tr[1]=(heights[i]+heights[i+1])/2
 else:
  p+=tr; x=p[:,0].copy(); p[:,1]+=np.interp(x,boundaries,heights)
  s=slopes[np.clip(np.searchsorted(boundaries,x,side='right')-1,0,16)]
  s[(x<boundaries[0])|(x>boundaries[-1])]=0
  norm[:,0]-=s*norm[:,1]
  tr=(p.min(0)+p.max(0))/2; p-=tr
 norm/=np.maximum(np.linalg.norm(norm,axis=1,keepdims=True),1e-8)
 node['translation']=tr.tolist(); write(attrs['POSITION'],p);write(attrs['NORMAL'],norm)
 assert np.isfinite(p).all() and np.isfinite(norm).all()
assert max(abs(slopes))<1.0 and heights[0]==heights[1]==heights[-1]==heights[-2]==0
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*(-len(j)%4);binary+=b'\0'*(-len(binary)%4)
out=struct.pack('<4sII',b'glTF',2,28+len(j)+len(binary))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(binary),b'BIN\0')+binary
(arena/'Bridge_Curved.glb').write_bytes(out)
print('17 planks, depth',-min(heights),'max slope degrees',np.degrees(np.arctan(max(abs(slopes)))))
