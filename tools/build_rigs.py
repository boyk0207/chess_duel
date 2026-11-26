import sys,json,struct,math,shutil
from pathlib import Path
import numpy as np
from scipy.spatial.transform import Rotation
A=Path(__file__).resolve().parents[1]/'assets'; OUT=A/'rigs'; OUT.mkdir(exist_ok=True)
def read(name):
 v=[]; uv=[]; n=[]; f=[]
 for l in (A/(name+'.obj')).read_text().splitlines():
  p=l.split()
  if not p:continue
  if p[0]=='v':v.append(list(map(float,p[1:4])))
  if p[0]=='vt':uv.append(list(map(float,p[1:3])))
  if p[0]=='vn':n.append(list(map(float,p[1:4])))
  if p[0]=='f':f.append([tuple(int(x)-1 if x else -1 for x in q.split('/')) for q in p[1:]])
 return np.array(v),np.array(uv),np.array(n),f
# absolute rest pivots in source OBJ coordinates; W normalized after split.
profiles={
'P':('croc',{'Spine':('Root',(-.12,.30,.02)), 'Head':('Spine',(-.12,.65,-.14)), 'Tail':('Root',(-.12,.12,.12)), 'TailTip':('Tail',(-.12,.12,.29)), 'ArmL':('Spine',(-.22,.60,-.06)), 'ArmR':('Spine',(-.02,.60,-.06)), 'LegL':('Root',(-.20,.23,.03)), 'LegR':('Root',(-.06,.23,.03)), 'WeaponJoint':('ArmR',(.20,.55,-.0875))}),
'N':('monitor_body',{'Spine':('Root',(0,.22,-.15)), 'Head':('Spine',(0,.40,-.45)), 'Tail':('Root',(0,.16,.26)), 'TailTip':('Tail',(0,.16,.56)), 'FrontL':('Spine',(-.17,.18,-.39)), 'FrontR':('Spine',(.17,.18,-.39)), 'BackL':('Root',(-.17,.18,.39)), 'BackR':('Root',(.17,.18,.39))}),
'B':('wizard',{'Spine':('Root',(0,.28,-.18)), 'Head':('Spine',(0,.66,-.27)), 'Tail':('Root',(0,.12,.19)), 'TailTip':('Tail',(0,.13,.36)), 'ArmR':('Spine',(0,.43,-.25)), 'WeaponJoint':('ArmR',(0,.38,-.425))}),
'R':('bomb',{'Spine':('Root',(0,.30,-.04)), 'Head':('Spine',(0,.20,-.36)), 'Tail':('Root',(0,.30,.34)), 'TailTip':('Tail',(0,.65,.48)), 'LegL':('Root',(-.18,.15,-.10)), 'LegR':('Root',(.18,.15,-.10)), 'WeaponJoint':('Spine',(.32,.65,-.30))}),
'Q':('snakegod',{'Spine':('Root',(0,.22,-.22)), 'Head':('Spine',(0,.43,-.31)), 'Tail':('Root',(0,.10,.10)), 'TailTip':('Tail',(0,.10,.32)), 'CrownJoint':('Head',(0,.70,-.28))}),
'K':('snakeking',{'Spine':('Root',(0,.22,-.20)), 'Head':('Spine',(0,.55,-.22)), 'Tail':('Root',(0,.10,.13)), 'TailTip':('Tail',(0,.14,.34)), 'CrownJoint':('Head',(0,.90,-.16))}),
'W':('monitor_rider',{'Spine':('Root',(0,.52,.02)), 'Head':('Spine',(0,.74,-.10)), 'Tail':('Root',(0,.53,.17)), 'TailTip':('Tail',(0,.55,.32)), 'ArmL':('Spine',(-.15,.69,-.08)), 'ArmR':('Spine',(.12,.69,-.08)), 'LegL':('Root',(-.10,.46,.04)), 'LegR':('Root',(.10,.46,.04)), 'WeaponJoint':('ArmR',(.18,.76,-.20)), 'OffhandJoint':('ArmL',(-.22,.62,-.10))})}
clips={'Idle':1.6,'Walk':.78,'Run':.52,'JumpStart':.16,'Airborne':.55,'Landing':.24,'Dodge':.20,'Block':.45,'PerfectBlock':.26,'Attack':.30,'Special':.60,'Hit':.22,'Death':.75,'Victory':1.4}
loop={'Idle','Walk','Run','Airborne','Block'}

def segment(k,p,uv):
 x,y,z=p
 if k=='P' and uv in [0,4,8]:return 'Weapon'
 if k=='B' and uv in [1,3,8]:return 'Weapon'
 if k=='W' and uv==4:return 'Weapon' if x>0 else 'Offhand'
 if k=='Q' and uv==5 and y>=.70:return 'Crown'
 if k=='K' and uv==4:return 'Crown'
 return 'Body'

def weights(k,p):
 x,y,z=p
 # return two-bone linear blend around broad anatomical joints; keep all duplicated vertex weights equal.
 def blend(a,b,t):
  t=float(np.clip(t,0,1));return [(a,1-t),(b,t)]
 if k=='N':
  if y<.26 and abs(x)>.15:
   leg=('Front' if z<0 else 'Back')+('R' if x>0 else 'L');return blend('Spine' if z<0 else 'Root',leg,(abs(x)-.14)/.10)
  if z>.26:return blend('Tail','TailTip',(z-.42)/.20)
  if z>.10:return blend('Root','Tail',(z-.10)/.16)
  if z<-.35 and y>.27:return blend('Spine','Head',min((-.35-z)/.20,(y-.27)/.16))
  return blend('Root','Spine',(y-.10)/.22)
 if k in ['P','W']:
  if z>(.15 if k=='P' else .17) and y<(.38 if k=='P' else .68):return blend('Tail','TailTip',(z-.23)/.13)
  if k=='P':
   if y<.26:return blend('Root','LegR' if x>-.13 else 'LegL',(.26-y)/.15)
   if y>.46 and x>.0 and y<.74:return blend('Spine','ArmR',x/.12)
   if y>.40 and x<-.21 and y<.72:return blend('Spine','ArmL',(-.21-x)/.07)
   if y>.60:return blend('Spine','Head',(y-.60)/.13)
   return blend('Root','Spine',(y-.22)/.17)
  if y<.48:return blend('Root','LegR' if x>0 else 'LegL',(.48-y)/.14)
  if y>.59 and y<.80 and abs(x)>.10:return blend('Spine','ArmR' if x>0 else 'ArmL',(abs(x)-.10)/.07)
  if y>.72:return blend('Spine','Head',(y-.72)/.10)
  return blend('Root','Spine',(y-.48)/.13)
 if k=='R':
  if z>.35:return blend('Tail','TailTip',(z-.42)/.18)
  if z>.18:return blend('Spine','Tail',(z-.18)/.18)
  if z<-.28 and y<.38:return blend('Spine','Head',(-.28-z)/.22)
  if y<.14 and abs(x)>.12:return blend('Root','LegR' if x>0 else 'LegL',(.14-y)/.10)
  return blend('Root','Spine',(y-.10)/.26)
 if z>.13 and y<.40:return blend('Tail','TailTip',(z-.20)/.19)
 if z>-.01 and y<.28:return blend('Root','Tail',(z+.01)/.14)
 if k=='B' and y>.30 and y<.57 and z<-.27:return blend('Spine','ArmR',(-.27-z)/.13)
 head={'B':.64,'Q':.43,'K':.52}[k]
 if y>head:return blend('Spine','Head',(y-head)/.14)
 return blend('Root','Spine',(y-.10)/.20)

# Art-directed rotation tracks (degrees) for each anatomically named bone; no shader deformation.
styles={'P':(1.0,1.0,1.0),'N':(1.35,.75,.70),'B':(.70,.60,1.35),'R':(.65,1.35,.75),'Q':(.85,.60,1.45),'K':(.65,1.05,.90),'W':(1.15,1.15,1.15)}
def pose(k,clip,b,t):
 rate,heavy,flow=styles[k]; s=math.sin(2*math.pi*t); c=math.cos(2*math.pi*t); p=math.sin(math.pi*t); a=np.zeros(3); tr=np.zeros(3)
 # local rotations with the same rest pivot for all clips
 if clip in ['Idle','Walk','Run']:
  gain={'Idle':.12,'Walk':.60,'Run':1.0}[clip]
  if b=='Root':tr[1]=(.006 if clip=='Idle' else .035*heavy*gain)*(1-c)/2
  if b=='Spine':a=[-8*gain*rate+3*s*gain, 6*s*gain*flow, 4*c*gain]
  if b=='Head':a=[-4*c*gain,4*s*gain,0]
  if b.startswith('Tail'):a=[3*c*gain, (21 if b=='TailTip' else 13)*s*flow*gain, 4*s*gain]
  if b.startswith(('Leg','Front','Back','Arm')):
   side=1 if b.endswith('R') else -1; side*= -1 if b.startswith(('Back','Arm')) else 1
   a=[(32 if 'Leg' in b or 'Front' in b or 'Back' in b else 20)*s*side*gain*rate,0,3*c*side*gain]
  if b in ('WeaponJoint','OffhandJoint'):a=[8*s*gain,0,3*c*gain]
  if b=='CrownJoint':tr[1]=.008*s
 elif clip in ['JumpStart','Airborne','Landing']:
  q=(t if clip=='JumpStart' else (.7+.3*s if clip=='Airborne' else p))
  if b=='Root':tr[1]=-.055*q*heavy if clip!='Airborne' else .015*q
  if b=='Spine':a=[(18 if clip=='Landing' else -14)*q*heavy,0,0]
  if b=='Head':a=[-10*q,0,0]
  if b.startswith('Tail'):a=[-18*q,12*q*flow,0]
  if b.startswith(('Leg','Front','Back')):a=[(-35 if b.startswith('Front') else 30)*q,0,8*q*(1 if b.endswith('R') else -1)]
  if b.startswith('Arm'):a=[-25*q,0,12*q*(1 if b.endswith('R') else -1)]
  if b.endswith('Joint'):a=[-25*q,0,0]
 elif clip in ['Block','PerfectBlock']:
  q=1 if clip=='Block' else p
  if b=='Root':tr[1]=-.06*q*heavy
  if b=='Spine':a=[15*q*heavy,0,0]
  if b=='Head':a=[-12*q,0,0]
  if b.startswith('Tail'):a=[8*q,24*q*flow,0]
  if b.startswith(('Leg','Front','Back')):a=[18*q,0,8*q*(1 if b.endswith('R') else -1)]
  if b.startswith('Arm'):a=[-30*q,0,(-25 if b.endswith('R') else 25)*q]
  if b=='WeaponJoint':a=[-18*q,0,-65*q if k in ('P','W') else -20*q]
  if b=='OffhandJoint':a=[-30*q,0,55*q]
  if b=='CrownJoint':tr[1]=.04*q
 elif clip=='Dodge':
  if b=='Root':a=[-12*p,0,(45 if k in ('P','R') else 22)*p];tr[1]=-.065*p
  if b=='Spine':a=[-12*p,22*p*flow,12*p]
  if b.startswith('Tail'):a=[-20*p,35*p*flow,0]
  if b.startswith(('Leg','Front','Back','Arm')):a=[35*p,0,10*p]
  if b.endswith('Joint'):a=[25*p,0,0]
 elif clip in ['Attack','Special']:
  special=clip=='Special'; gain=1.45 if special else 1.; swing=math.sin(2*math.pi*t)*(1 if k!='Q' or special else 0.0); swing=math.sin(4*math.pi*t) if k=='Q' and not special else swing
  if b=='Root':tr[2]=-.025*p*heavy
  if b=='Spine':a=[(-25*p if k=='N' else 22*swing)*gain*heavy, 22*swing*gain*flow, 12*p*gain]
  if b=='Head':a=[(24 if k=='N' else -10)*p*gain,12*swing*flow,0]
  if b.startswith('Tail'):a=[8*p,35*swing*flow,8*p]
  if b.startswith(('Leg','Front','Back')):a=[20*p*(-1 if b.endswith('R') else 1),0,0]
  if b.startswith('Arm'):a=[-44*p*gain,30*swing*gain,(-25 if b.endswith('R') else 25)*p]
  if b=='WeaponJoint':
   a=[(-85*p if k=='P' else -55*swing)*gain, 35*swing*gain, (-55*p if k=='W' else 8*swing)*gain]
   if k=='P':tr[2]=-.08*p
  if b=='OffhandJoint':a=[-50*swing*gain,-30*swing,40*p]
  if b=='CrownJoint':tr[1]=.07*p*gain;a=[0,45*swing,0]
 elif clip=='Hit':
  if b=='Root':tr[2]=.055*p
  if b=='Spine':a=[-28*p,0,12*p]
  if b=='Head':a=[-16*p,12*p,0]
  if b.startswith('Tail'):a=[12*p,-25*p,0]
  if b.startswith('Arm') or b.endswith('Joint'):a=[28*p,0,20*p]
 elif clip=='Death':
  q=t*t*(3-2*t)
  if b=='Root':a=[0,0,80*q];tr[1]=-.12*q
  if b=='Spine':a=[-16*q,0,10*q]
  if b.startswith('Tail'):a=[10*q,25*q,0]
  if b.startswith('Arm') or b.endswith('Joint'):a=[25*q,0,35*q]
  if b=='CrownJoint':tr[1]=-.14*q
 elif clip=='Victory':
  if b=='Spine':a=[-18*p,15*s,0]
  if b=='Head':a=[-20*p,0,0]
  if b.startswith('Tail'):a=[0,25*s,0]
  if b.startswith('Arm'):a=[-65*p,0,15*p]
  if b.endswith('Joint'):a=[-40*p,30*s,0]
  if b=='CrownJoint':tr[1]=.05*p
 return a,tr

class GLB:
 def __init__(self):
  self.buf=bytearray();self.j={'asset':{'version':'2.0','generator':'Chess Duel voxel skin rig generator'},'scene':0,'scenes':[{'nodes':[]}],'nodes':[],'meshes':[],'skins':[],'animations':[],'bufferViews':[],'accessors':[],'buffers':[{}]}
 def view(self,raw,target=None):
  self.buf.extend(b'\0'*(-len(self.buf)%4));off=len(self.buf);self.buf.extend(raw);v={'buffer':0,'byteOffset':off,'byteLength':len(raw)}
  if target:v['target']=target
  self.j['bufferViews'].append(v);return len(self.j['bufferViews'])-1
 def acc(self,a,typ,ct=5126,target=None,bounds=False):
  a=np.asarray(a,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[ct]);v={'bufferView':self.view(a.tobytes(),target),'componentType':ct,'count':len(a),'type':typ}
  if bounds:v.update(min=np.min(a,axis=0).reshape(-1).tolist(),max=np.max(a,axis=0).reshape(-1).tolist())
  self.j['accessors'].append(v);return len(self.j['accessors'])-1
 def node(self,name,**kw):self.j['nodes'].append(dict(name=name,**kw));return len(self.j['nodes'])-1
 def save(self,path):
  self.buf.extend(b'\0'*(-len(self.buf)%4));self.j['buffers'][0]['byteLength']=len(self.buf);js=json.dumps(self.j,separators=(',',':')).encode();js+=b' '*(-len(js)%4)
  path.write_bytes(struct.pack('<4sII',b'glTF',2,12+8+len(js)+8+len(self.buf))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(self.buf),b'BIN\0')+self.buf)

def build(k):
 name,bones=profiles[k];g=GLB(); j=g.j; source=[]
 source=[(read(name),None)]
 def norm(p):return (np.asarray(p)-np.array([0,.24,0]))/.76 if k=='W' else np.asarray(p)
 root=g.node('Rig');j['scenes'][0]['nodes']=[root]; j['nodes'][root]['children']=[]
 absolute={'Root':np.zeros(3)}; parents={'Root':None}
 for b,(parent,p) in bones.items():absolute[b]=norm(p);parents[b]=parent
 bn=list(absolute); bone_nodes={}; inv=[]
 for b in bn:
  par=parents[b];local=absolute[b]-(absolute[par] if par else 0);idx=g.node(b,translation=local.tolist());bone_nodes[b]=idx
  parent=bone_nodes[par] if par else root;j['nodes'][parent].setdefault('children',[]).append(idx)
  m=np.eye(4);m[:3,3]=-absolute[b];inv.append(m.T.reshape(-1))
 j['skins']=[{'name':'VoxelSkeleton','joints':[bone_nodes[b] for b in bn],'skeleton':bone_nodes['Root'],'inverseBindMatrices':g.acc(inv,'MAT4')}]
 j['images']=[{'bufferView':g.view((A/(name+'.png')).read_bytes()),'mimeType':'image/png'}];j['samplers']=[{'magFilter':9728,'minFilter':9728,'wrapS':33071,'wrapT':33071}];j['textures']=[{'source':0,'sampler':0}];j['materials']=[{'name':'Palette','doubleSided':True,'pbrMetallicRoughness':{'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':1}}]
 parts={}
 for (verts,uvs,normals,faces),forced in source:
  for face in faces:
   for ti in range(1,len(face)-1):
    tri=[face[0],face[ti],face[ti+1]]; center=verts[[p[0] for p in tri]].mean(0); part=forced or segment(k,center,tri[0][1]);data=parts.setdefault(part,[[],[],[],[],[]])
    for vi,ui,ni in tri:
     p=verts[vi]; data[0].append(norm(p)); data[1].append(normals[ni]);data[2].append([uvs[ui][0],1-uvs[ui][1]])
     ws=weights(k,p) if part=='Body' else [({'Weapon':'WeaponJoint','Offhand':'OffhandJoint','Crown':'CrownJoint'}[part],1.)]
     data[3].append([bn.index(b) for b,w in ws]+[0]*(4-len(ws)));data[4].append([w for b,w in ws]+[0.]*(4-len(ws)))
 for part,(v,n,uv,ji,wt) in parts.items():
  if part != 'Body':
   dest=OUT/'separated';dest.mkdir(exist_ok=True)
   key=k+'_'+part; pivot=absolute[{'Weapon':'WeaponJoint','Offhand':'OffhandJoint','Crown':'CrownJoint'}[part]]
   lines=['# Separate voxel mesh; origin at rig joint','mtllib '+key+'.mtl','o '+key]
   lines+=['v %.6f %.6f %.6f'%tuple(np.asarray(x)-pivot) for x in v]
   lines+=['vt %.6f %.6f'%(x[0],1-x[1]) for x in uv]
   lines+=['vn %.6f %.6f %.6f'%tuple(x) for x in n]
   lines+=['usemtl palette']+['f '+' '.join('%d/%d/%d'%(i,i,i) for i in range(a+1,a+4)) for a in range(0,len(v),3)]
   (dest/(key+'.obj')).write_text('\n'.join(lines)+'\n')
   (dest/(key+'.mtl')).write_text('newmtl palette\nKd 1 1 1\nmap_Kd '+name+'.png\n')
   shutil.copy2(A/(name+'.png'),dest/(name+'.png'))
  assert np.allclose(np.sum(wt,axis=1),1); attrs={'POSITION':g.acc(v,'VEC3',target=34962,bounds=True),'NORMAL':g.acc(n,'VEC3',target=34962),'TEXCOORD_0':g.acc(uv,'VEC2',target=34962),'JOINTS_0':g.acc(ji,'VEC4',5123,34962),'WEIGHTS_0':g.acc(wt,'VEC4',target=34962)}
  j['meshes'].append({'name':part,'primitives':[{'attributes':attrs,'material':0,'mode':4}]});nd=g.node(part,mesh=len(j['meshes'])-1,skin=0);j['nodes'][root]['children'].append(nd)
 for clip,dur in clips.items():
  anim={'name':clip,'samplers':[],'channels':[]}; times=np.linspace(0,dur,17);time_acc=g.acc(times,'SCALAR',bounds=True)
  for b in bn:
   vals=[pose(k,clip,b,i/16) for i in range(17)];rot=Rotation.from_euler('XYZ',[a for a,tr in vals],degrees=True).as_quat();local=absolute[b]-(absolute[parents[b]] if parents[b] else 0);trans=[local+tr for a,tr in vals]
   for path,data,typ in [('rotation',rot,'VEC4'),('translation',trans,'VEC3')]:
    acc=g.acc(data,typ);anim['samplers'].append({'input':time_acc,'output':acc,'interpolation':'LINEAR'});anim['channels'].append({'sampler':len(anim['samplers'])-1,'target':{'node':bone_nodes[b],'path':path}})
  j['animations'].append(anim)
 g.save(OUT/(k+'.glb'));return {'kind':k,'name':name,'bones':len(bn),'clips':list(clips),'parts':{p:len(d[0])//3 for p,d in parts.items()}}
if __name__=='__main__':
 manifest=[build(k) for k in profiles]; (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)); print(json.dumps(manifest,indent=2))
