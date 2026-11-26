shader_type canvas_item;
uniform int effect = 0;
varying vec2 pos;
void vertex(){ pos = VERTEX; }
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 float a=COLOR.a;
 float n=noise(pos*0.16);
 float grain=hash(floor(pos));
 float vein=abs(sin(pos.x*0.23+pos.y*0.31+noise(pos*0.09)*6.0));
 float crack=1.0-smoothstep(0.035,0.16,vein);
 float top=1.0-texture(TEXTURE,UV-vec2(0.0,2.0)*TEXTURE_PIXEL_SIZE).a;
 vec3 c;
 if(effect==4){
  c=mix(vec3(0.12,0.43,0.75),vec3(0.65,0.94,1.0),n);
  c=mix(c,vec3(0.93,0.99,1.0),max(top,crack*0.75));
  c+=vec3(0.12)*pow(max(0.0,sin(pos.x*0.19-pos.y*0.35+TIME*0.7)),18.0);
 }else if(effect==1){
  float heat=noise(pos*0.11+vec2(0.0,TIME*2.5));
  c=mix(vec3(1.0,0.68,0.34),vec3(1.0,0.89,0.66),n);
  c=mix(c,mix(vec3(1.0,0.48,0.16),vec3(1.0,0.97,0.65),heat),max(crack*0.45,top*0.45));
 }else if(effect==0){
  c=mix(vec3(0.28,0.34,0.30),vec3(0.75,0.79,0.65),n);
  c=mix(c,vec3(0.42,0.78,0.20),smoothstep(0.40,0.72,n+top*0.45));
  c*=1.0-crack*0.35;
 }else if(effect==2){
  c=mix(vec3(0.55,0.29,0.12),vec3(1.0,0.80,0.46),n);
  c*=1.0-crack*0.50;
 }else{
  c=mix(vec3(0.65,0.63,0.54),vec3(1.0,0.99,0.91),n);
  c=mix(c,vec3(0.95,0.70,0.23),max(top,crack*0.65));
 }
 COLOR=vec4(clamp(c+(grain-0.5)*0.10,0.0,1.0),a);
}
