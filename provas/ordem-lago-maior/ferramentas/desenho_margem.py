import json,math,sys
exec(open('ana.py').read().split('import sys')[0])
antes=json.load(open('../medicao/antes.json'))['lago']['margem_por_rumo_m']
COVA=(19.5,-19.0)
c0=(21.0,-21.0)
NB=72
def rmax_at(a, folga):
    r=0
    while r<22 and ok(c0[0]+math.sin(a)*r, c0[1]-math.cos(a)*r): r+=0.05
    return r-folga
RCAP=float(sys.argv[1]) if len(sys.argv)>1 else 13.0
FOLGA=0.6
rm=[rmax_at(2*math.pi*k/NB,FOLGA) for k in range(NB)]
# envelope: min over window, then smooth, iterate so r<=rm
r=[min(x,RCAP+1.5) for x in rm]
def wobble(k):
    a=2*math.pi*k/NB
    return 1.0+0.7*math.sin(3*a+0.8)+0.45*math.sin(5*a+2.1)+0.25*math.sin(7*a+0.3)
r=[min(r[k], RCAP+wobble(k)) for k in range(NB)]
for it in range(int(sys.argv[2]) if len(sys.argv)>2 else 60):
    s=[(r[(k-1)%NB]+2*r[k]+r[(k+1)%NB])/4 for k in range(NB)]
    r=[min(s[k], rm[k]) for k in range(NB)]
# chão: o lago velho fica todo dentro (a margem velha mais 0,35 m), sem passar o limite duro
def r_velho(a):
    # o raio da margem velha medido a partir de c0, no rumo a (marcha até sair do polígono velho)
    best=0
    d=0.0
    while d<16:
        x,z=c0[0]+math.sin(a)*d, c0[1]-math.cos(a)*d
        dx=x-COVA[0]; dz=z-COVA[1]; b=(math.atan2(dx,-dz)%(2*math.pi))/(2*math.pi)*24
        k=int(b)%24; u=b-int(b); rv=antes[k]*(1-u)+antes[(k+1)%24]*u
        if math.hypot(dx,dz)<rv: best=d
        d+=0.05
    return best
piso=[r_velho(2*math.pi*k/NB)+0.35 for k in range(NB)]
dur=[rmax_at(2*math.pi*k/NB,0.0) for k in range(NB)]
for it in range(int(sys.argv[3]) if len(sys.argv)>3 else 40):
    r=[min(max(r[k],piso[k]),dur[k]) for k in range(NB)]
    s2=[(r[(k-1)%NB]+2*r[k]+r[(k+1)%NB])/4 for k in range(NB)]
    r=[min(max(s2[k],piso[k]),dur[k]) for k in range(NB)]
r=[round(x,2) for x in r]
def R(a):
    t=(a/(2*math.pi)*NB)%NB; k=int(t); u=t-k
    p0,p1,p2,p3=r[(k-1)%NB],r[k],r[(k+1)%NB],r[(k+2)%NB]
    return 0.5*((2*p1)+(-p0+p2)*u+(2*p0-5*p1+4*p2-p3)*u*u+(-p0+3*p1-3*p2+p3)*u**3)
# shoreline points
costa=[]
for k in range(360):
    a=2*math.pi*k/360; rr=R(a); costa.append((c0[0]+math.sin(a)*rr, c0[1]-math.cos(a)*rr))
def dentro(x,z):
    dx=x-c0[0]; dz=z-c0[1]; a=math.atan2(dx,-dz)%(2*math.pi)
    return math.hypot(dx,dz)<R(a)
def sd(x,z):
    m=1e9
    for i in range(360):
        m=min(m,segd((x,z),costa[i],costa[(i+1)%360]))
    return m if dentro(x,z) else -m
# old lake containment
falha=0
for k in range(24):
    a=2*math.pi*k/24
    for f in (0.2,0.5,0.8,0.99):
        d=antes[k]*f
        if not dentro(COVA[0]+math.sin(a)*d, COVA[1]-math.cos(a)*d): falha+=1
print('fora do novo (velho):',falha)
# obstacles check
viol=[(o) for o in obs if sd(o[0],o[1])>-(o[2]-1.0)]
print('obstaculos perto:',viol)
print('raios',r)
json.dump({'c0':c0,'r':r},open('forma.json','w'))
for k in range(24):
    a=2*math.pi*k/24
    for f in (0.2,0.5,0.8,0.99):
        d=antes[k]*f
        x,z=COVA[0]+math.sin(a)*d, COVA[1]-math.cos(a)*d
        if not dentro(x,z):
            dx=x-c0[0]; dz=z-c0[1]; b=math.degrees(math.atan2(dx,-dz))%360
            print('falha',k*15,f,round(x,2),round(z,2),'rumo c0',round(b),'dist',round(math.hypot(dx,dz),2),'R',round(R(math.radians(b)),2),'rmax',round(rmax_at(math.radians(b),0),2))
