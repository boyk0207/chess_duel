"""Original procedural stereo soundtrack and additional combat cues. Requires NumPy/SciPy."""
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
from scipy.io.wavfile import write
OUT = Path(__file__).resolve().parents[1] / 'assets/audio/generated'
R = 44100
rng = np.random.default_rng(81025)
def hz(m): return 440*2**((m-69)/12)
def time(s): return np.arange(round(s*R))/R
def noise(t, lo, hi):
    return sosfilt(butter(2,[lo,hi],fs=R,btype='bandpass',output='sos'),rng.standard_normal(len(t)))
def save(name,y,peak=.76):
    y=y/max(1e-8,np.max(np.abs(y)))*peak
    write(OUT/(name+'.wav'),R,np.int16(np.clip(y,-1,1)*32767))
def env(t,a,d): return np.minimum(t/a,1)*np.exp(-t/d)
def add(buf,y,start,pan=0):
    idx=(round(start*R)+np.arange(len(y)))%len(buf)
    np.add.at(buf[:,0],idx,y*np.sqrt((1-pan)/2)); np.add.at(buf[:,1],idx,y*np.sqrt((1+pan)/2))
def tone(m,t,style):
    f=hz(m); p=2*np.pi*f*t
    if style=='pad':
        return (np.sin(p+0.22*np.sin(2*np.pi*4.2*t))+.32*np.sin(2*p)+.15*np.sin(3*p)+.22*np.sin(p*1.003))*np.sin(np.pi*np.minimum(t/t[-1],1))**.7
    if style=='pluck': return (np.sin(p)+.4*np.sin(2*p)*np.exp(-t*5)+.22*np.sin(3*p)*np.exp(-t*9))*env(t,.008,.36)
    return (np.sin(p)+.15*np.sin(2*p)+.1*np.sin(p*2.76))*env(t,.012,.65)
def music(name,bpm,chords,melody,drums=False,intense=False):
    beat=60/bpm; bars=8; buf=np.zeros((round(bars*4*beat*R),2));
    for bar in range(bars):
        chord=chords[bar%len(chords)]; start=bar*4*beat
        if not intense:
            for j,m in enumerate(chord):
                t=time(4.7*beat); add(buf,.12*tone(m,t,'pad'),start-.3*beat,[-.55,.2,.55,0][j%4])
            for k in (0,2):
                t=time(1.9*beat); add(buf,.13*tone(chord[0]-12,t,'pluck'),start+k*beat,-.1)
        for k in range(4 if not drums else 8):
            m=chord[(k+bar)%len(chord)]+12
            t=time(1.7*beat); add(buf,(.065 if not intense else .09)*tone(m,t,'pluck'),start+k*beat*(1 if not drums else .5),(-1)**k*.35)
        for k in range(4):
            m=melody[(bar*4+k)%len(melody)]
            if m:
                t=time(2.1*beat); add(buf,(.12 if not intense else .07)*tone(m,t,'bell'),start+k*beat,.12)
        if drums:
            for k in ([0,1.5,2,3.5] if intense else [0,2]):
                t=time(.44); kick=np.sin(2*np.pi*(45*t+38*(1-np.exp(-t*24))/24))*env(t,.004,.12)
                add(buf,kick*(.28 if intense else .32),start+k*beat)
            for k in ([1,3] if intense else [3]):
                t=time(.32); hit=noise(t,120,1800)*env(t,.004,.10)+.28*np.sin(2*np.pi*133*t)*env(t,.004,.075)
                add(buf,hit*.19,start+k*beat,.22)
    dry=buf.copy()
    for delay,g in [(0.11,.16),(.23,.12),(.39,.07)]: buf+=g*np.roll(dry[:,::-1],round(delay*R),axis=0)
    save(name,np.tanh(buf*1.8),.66 if not intense else .5)
ch=[[45,52,57,60],[41,48,53,57],[43,50,55,59],[40,47,52,56]]
music('menu',84,ch,[69,0,72,76,74,0,72,0,67,69,0,71,68,0,64,0,69,72,76,0,77,76,72,0,71,0,74,67,68,0,64,0])
music('board',100,[[48,55,60,64],[45,52,57,60],[50,57,62,65],[43,50,55,59]],[72,0,67,0,69,0,64,0,65,69,0,74,71,0,67,0])
music('battle',120,ch,[69,0,72,0,65,0,69,0,67,0,71,0,68,0,64,0],True)
music('battle_intense',120,ch,[81,76,79,72,77,72,76,71],True,True)
for name,d,lo,hi in [('swing',.27,350,7500),('heavy_swing',.4,100,4100),('dodge',.34,220,6200),('cast_release',.42,300,6500),('magic_impact',.64,90,3200)]:
    t=time(d); shape=np.sin(np.pi*np.minimum(t/d,1))**2
    y=noise(t,lo,hi)*shape
    if name in ['heavy_swing','magic_impact']: y+=.6*np.sin(2*np.pi*(65*t+2*(1-np.exp(-t*25))))*env(t,.012,.13)
    if name=='cast_release': y+=.35*np.sin(2*np.pi*(240*t+550*t*t))*shape
    save(name,y,.7)
for name,notes in [('shard',[76,81,88]),('victory',[57,64,69,72,76]),('defeat',[57,53,48,45])]:
    d=1.0 if name=='shard' else 2.5; b=np.zeros((round(d*R),2))
    for j,m in enumerate(notes):
        start=j*(.09 if name=='shard' else .24); t=time(d-start-.03); add(b,.2*tone(m,t,'bell'),start,(-1)**j*.3)
    b*=np.minimum(1,np.arange(len(b))[::-1]/(R*.12))[:,None]; save(name,b,.73)
