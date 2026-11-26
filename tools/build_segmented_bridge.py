import json,struct,numpy as np,collections,pathlib
p=pathlib.Path(__file__).resolve().parents[1] / 'assets' / 'arena' / 'Bridge.glb'; b=p.read_bytes(); n=struct.unpack_from('<I',b,12)[0]; orig=json.loads(b[20:20+n]); raw=b[28+n:]
def arr(i,dtype,dim):
 a=orig['accessors'][i];v=orig['bufferViews'][a['bufferView']];return np.frombuffer(raw,dtype,count=a['count']*dim,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,dim).copy()
pos=arr(1,'<f4',3); uv=arr(2,'<f4',2); norm=arr(3,'<f4',3);faces=arr(0,'<u4',1).reshape(-1,3)
# Connectivity by coincident position, retaining original UV seams and normals.
parent=list(range(len(faces))); owners={}
def root(x):
 while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
 return x
for i,tri in enumerate(faces):
 for v in tri:
  k=tuple(np.round(pos[v],5));j=owners.setdefault(k,i);parent[root(i)]=root(j)
components=collections.defaultdict(list)
for i in range(len(faces)):components[root(i)].append(i)
planks=[];others=[]
for ids in components.values():
 vs=pos[faces[ids].ravel()]; lo=vs.min(0);hi=vs.max(0); span=hi-lo
 if len(ids)==12 and span[2]>1.5 and span[0]<0.7:planks.append(ids)
 elif span[0]>5:
  for side in [-1,1]:
   sub=[i for i in ids if (1 if pos[faces[i],0].mean()>=0 else -1)==side]
   if sub:others.append(('Rope',sub))
 else:others.append(('Post',ids))
planks.sort(key=lambda ids:pos[faces[ids].ravel(),0].mean()); assert len(planks)==17,len(planks)
groups=[(f'Plank_{i:02}',ids) for i,ids in enumerate(planks)]+[(f'{name}_{i:02}',ids) for i,(name,ids) in enumerate(others)]
assert sorted(i for _,ids in groups for i in ids)==list(range(len(faces)))
# Preserve source texture and sampler/material. Keep original binary prefix for image.
d={k:v for k,v in orig.items() if k not in ('nodes','meshes','accessors','scenes','buffers')};d['nodes']=[];d['meshes']=[];d['accessors']=[];d['scenes']=[{'nodes':[]}];d['scene']=0
buf=bytearray(raw[:orig['buffers'][0]['byteLength']]);scale=np.array([.47,.75,1.35],dtype=np.float32)
def write(a,ctype,typ,target):
 while len(buf)%4:buf.append(0)
 offset=len(buf);data=a.tobytes();buf.extend(data);vi=len(d['bufferViews']);d['bufferViews'].append(dict(buffer=0,byteOffset=offset,byteLength=len(data),target=target));ai=len(d['accessors']);d['accessors'].append(dict(bufferView=vi,componentType=ctype,count=len(a),type=typ,min=a.min(0).reshape(-1).tolist(),max=a.max(0).reshape(-1).tolist()));return ai
meta=[]
for name,ids in groups:
 inds=faces[ids].ravel(); unique,inv=np.unique(inds,return_inverse=True);v=pos[unique]*scale;center=(v.min(0)+v.max(0))/2; v-=center;nn=norm[unique]/scale;nn/=np.maximum(np.linalg.norm(nn,axis=1,keepdims=True),1e-8)
 attrs={'POSITION':write(v.astype('<f4'),5126,'VEC3',34962),'NORMAL':write(nn.astype('<f4'),5126,'VEC3',34962),'TEXCOORD_0':write(uv[unique].astype('<f4'),5126,'VEC2',34962)}
 ind=write(inv.astype('<u2'),5123,'SCALAR',34963);mi=len(d['meshes']);d['meshes'].append({'name':name,'primitives':[{'attributes':attrs,'indices':ind,'material':0,'mode':4}]});ni=len(d['nodes']);d['nodes'].append({'name':name,'mesh':mi,'translation':center.tolist()});d['scenes'][0]['nodes'].append(ni);meta.append((name,center.tolist(),(v.max(0)-v.min(0)).tolist()))
while len(buf)%4:buf.append(0)
d['buffers']=[{'byteLength':len(buf)}];j=json.dumps(d,separators=(',',':')).encode();j+=b' '*(-len(j)%4);out=struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(buf))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(buf),b'BIN\x00')+buf
p.with_name('Bridge_Segmented.glb').write_bytes(out);print('groups',len(groups),'planks',len(planks),'faces',len(faces));print(meta)
