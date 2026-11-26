"""Offline binary/skin/clip integrity validation; does not replace Godot testing."""
import json,struct
from pathlib import Path
import numpy as np
from scipy.spatial.transform import Rotation
BASE=Path(__file__).resolve().parents[1]/'assets'/'rigs'
SIZES={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
TYPES={5126:'<f4',5123:'<u2',5125:'<u4'}
EXPECTED={'Idle','Walk','Run','JumpStart','Airborne','Landing','Dodge','Block','PerfectBlock','Attack','Special','Hit','Death','Victory','DodgeForward','DodgeBack','DodgeLeft','DodgeRight','Attack2','Attack3'}
def verify(path):
 raw=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',raw);assert (magic,version,length)==(b'glTF',2,len(raw))
 l,tag=struct.unpack_from('<I4s',raw,12);assert tag==b'JSON';j=json.loads(raw[20:20+l]);bl,bt=struct.unpack_from('<I4s',raw,20+l);assert bt==b'BIN\0';blob=raw[28+l:];assert len(blob)==bl==j['buffers'][0]['byteLength']
 def a(i):
  acc=j['accessors'][i];v=j['bufferViews'][acc['bufferView']];off=v.get('byteOffset',0)+acc.get('byteOffset',0);n=acc['count']*SIZES[acc['type']];dt=np.dtype(TYPES[acc['componentType']]);assert off+n*dt.itemsize<=v.get('byteOffset',0)+v['byteLength']<=len(blob);out=np.frombuffer(blob,dtype=dt,count=n,offset=off).reshape(acc['count'],-1);assert np.isfinite(out).all();return out
 for i in range(len(j['accessors'])):a(i)
 skin=j['skins'][0];joints=skin['joints'];inv=a(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1);assert len(inv)==len(joints)
 parents={c:i for i,n in enumerate(j['nodes']) for c in n.get('children',[])}
 rest={i:np.array(n.get('translation',[0,0,0]),float) for i,n in enumerate(j['nodes'])}
 def matrices(trans,rot):
  worlds={}
  def world(i):
   if i not in worlds:
    m=np.eye(4);m[:3,3]=trans.get(i,rest[i]);m[:3,:3]=rot.get(i,np.eye(3));worlds[i]=world(parents[i])@m if i in parents else m
   return worlds[i]
  return np.stack([world(i) for i in joints])@inv
 assert np.allclose(matrices({},{}),np.eye(4),atol=2e-6)
 meshes=[]
 for mesh in j['meshes']:
  for prim in mesh['primitives']:
   at=prim['attributes'];pos=a(at['POSITION']);ids=a(at['JOINTS_0']);w=a(at['WEIGHTS_0']);assert len(pos)%3==0 and len(pos)==len(ids)==len(w);assert np.all(ids<len(joints)) and np.all(w>=0) and np.allclose(w.sum(1),1);meshes.append((np.c_[pos,np.ones(len(pos))],ids,w))
 assert {x['name'] for x in j['animations']}==EXPECTED and len(j['animations'])==20
 frames=0;max_displacement=0.
 for anim in j['animations']:
  for ch in anim['channels']:
   sam=anim['samplers'][ch['sampler']];ts=a(sam['input']).ravel();output=a(sam['output']);assert len(ts)==len(output) and ts[0]==0 and np.all(np.diff(ts)>0)
   assert ch['target']['node'] in joints
   if ch['target']['path']=='rotation':assert np.allclose(np.linalg.norm(output,axis=1),1,atol=2e-5)
  for frame in range(17):
   trans={};rot={}
   for ch in anim['channels']:
    val=a(anim['samplers'][ch['sampler']]['output'])[frame];idx=ch['target']['node']
    if ch['target']['path']=='translation':trans[idx]=val
    else:rot[idx]=Rotation.from_quat(val).as_matrix()
   mat=matrices(trans,rot)
   for v,ids,w in meshes:
    p=np.einsum('nijk,nk->nij',mat[ids],v);p=(p*w[:,:,None]).sum(1);assert np.isfinite(p).all();assert np.allclose(p[:,3],1,atol=2e-6);max_displacement=max(max_displacement,float(np.max(np.linalg.norm(p[:,:3]-v[:,:3],axis=1))))
   frames+=1
 return {'file':path.name,'bones':len(joints),'clips':len(j['animations']),'mesh_parts':len(j['meshes']),'triangles':sum(len(v)//3 for v,_,_ in meshes),'sampled_frames':frames,'max_vertex_displacement':round(max_displacement,4)}
if __name__=='__main__':
 report=[verify(p) for p in sorted(BASE.glob('?.glb'))];assert len(report)==7 and sum(r['clips'] for r in report)==140
 print(json.dumps(report,indent=2))
 print('PASS: seven GLBs; 140 clips; 2380 sampled poses; bind matrices, skin weights, accessors, quaternions and vertex transforms validated.')
