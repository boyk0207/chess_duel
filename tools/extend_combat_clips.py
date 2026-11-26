"""Append combat clips to original GLB without changing existing accessors/geometry."""
import json,struct,math
from pathlib import Path
import numpy as np
from scipy.spatial.transform import Rotation
from build_rigs import GLB,pose,styles
BASE=Path(__file__).resolve().parents[1]/'assets'/'rigs'
EXTRA={'DodgeForward':.20,'DodgeBack':.20,'DodgeLeft':.20,'DodgeRight':.20,'Attack2':.30,'Attack3':.30}
def extend(path):
 k=path.stem; raw=path.read_bytes(); n=struct.unpack_from('<I',raw,12)[0]; g=GLB();g.j=json.loads(raw[20:20+n]);g.buf=bytearray(raw[28+n:]);j=g.j
 assert len(j['animations'])==14
 for name,duration in EXTRA.items():
  a={'name':name,'samplers':[],'channels':[]}; ts=g.acc(np.linspace(0,duration,17),'SCALAR',bounds=True)
  for idx in j['skins'][0]['joints']:
   node=j['nodes'][idx]; b=node['name']; rest=np.array(node['translation']); rotations=[];translations=[]
   for frame in range(17):
    t=frame/16; p=math.sin(math.pi*t); rate,heavy,flow=styles[k]
    angles,shift=pose(k,'Dodge' if name.startswith('Dodge') else 'Attack',b,t); angles=np.asarray(angles,float);shift=np.asarray(shift,float)
    if name.startswith('Dodge'):
     # Face the enemy while leaning into the actual dodge direction.
     side=-1 if name=='DodgeLeft' else 1 if name=='DodgeRight' else 0
     front=1 if name=='DodgeForward' else -1 if name=='DodgeBack' else 0
     angles[1:]*=side
     if b=='Root': angles=np.array([-27*front*p,0, (38 if k in ('P','R') else 24)*side*p]);shift[0]=.018*side*p
     if b=='Spine': angles[0]=-19*front*p;angles[2]+=side*8*p
     if b.startswith(('Leg','Front','Back')): angles[0]*=(1 if front>=0 else -1)
    elif name=='Attack2':
     angles[1:]*=-1
     if b in ('Spine','Head'): angles[1]+= -16*p*flow
     if b in ('WeaponJoint','OffhandJoint','ArmR','ArmL'): angles[2]+=(22 if b in ('WeaponJoint','ArmR') else -22)*p
     if k=='P' and b=='WeaponJoint': angles[0]*=.78;shift[2]*=1.15
    elif name=='Attack3':
     angles*=1.23
     if b=='Root': shift[2]-=.035*p
     if b=='Spine': angles[0]+=(-12 if k=='N' else 10)*p*heavy
     if b=='WeaponJoint': angles[0]-=17*p
     if b=='OffhandJoint': angles[2]-=22*p
    rotations.append(Rotation.from_euler('XYZ',angles,degrees=True).as_quat());translations.append(rest+shift)
   for prop,data,typ in [('rotation',rotations,'VEC4'),('translation',translations,'VEC3')]:
    ac=g.acc(data,typ);a['samplers'].append({'input':ts,'output':ac,'interpolation':'LINEAR'});a['channels'].append({'sampler':len(a['samplers'])-1,'target':{'node':idx,'path':prop}})
  j['animations'].append(a)
 g.save(path)
if __name__=='__main__':
 for path in sorted(BASE.glob('?.glb')): extend(path)
 manifest=json.loads((BASE/'manifest.json').read_text());
 for item in manifest:item['clips']+=list(EXTRA)
 (BASE/'manifest.json').write_text(json.dumps(manifest,indent=2))
