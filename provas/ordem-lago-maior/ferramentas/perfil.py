import json,math,sys
F=json.load(open('forma.json')); c0=F['c0']; r=F['r']; NB=len(r)
def R(a):
    t=(a/(2*math.pi)*NB)%NB; k=int(t); u=t-k
    p0,p1,p2,p3=r[(k-1)%NB],r[k],r[(k+1)%NB],r[(k+2)%NB]
    return 0.5*((2*p1)+(-p0+p2)*u+(2*p0-5*p1+4*p2-p3)*u*u+(-p0+3*p1-3*p2+p3)*u**3)
costa=[]
for k in range(360):
    a=2*math.pi*k/360; rr=R(a); costa.append((c0[0]+math.sin(a)*rr, c0[1]-math.cos(a)*rr))
def segd(p,a,b):
    ax,az=a;bx,bz=b;px,pz=p
    t=max(0,min(1,((px-ax)*(bx-ax)+(pz-az)*(bz-az))/((bx-ax)**2+(bz-az)**2)))
    return math.hypot(px-ax-t*(bx-ax),pz-az-t*(bz-az))
def sd(x,z):
    dx=x-c0[0]; dz=z-c0[1]; a=math.atan2(dx,-dz)%(2*math.pi)
    m=min(segd((x,z),costa[i],costa[(i+1)%360]) for i in range(360))
    return m if math.hypot(dx,dz)<R(a) else -m
def ss(a,b,v):
    t=max(0,min(1,(v-a)/(b-a))); return t*t*(3-2*t)
RASA=0.48; T0=float(sys.argv[1]); T1=float(sys.argv[2]); DB=float(sys.argv[3]); D1=float(sys.argv[4]); DMAX=2.45
def depth(s):
    if s<=0: return 0
    rasa=RASA*math.tanh(s/0.37)
    tal=ss(T0,T1,s)
    deep=DB+(DMAX-DB)*ss(T1,D1,s)
    return rasa+(deep-rasa)*tal
# fine 0.75 vertex grid then bilinear-ish: sample on vertices, measure with 0.25 grid by interpolation
P=0.75
xs=[c0[0]-14+i*P for i in range(int(28/P)+2)]; zs=[c0[1]-14+j*P for j in range(int(28/P)+2)]
D={}
for j,z in enumerate(zs):
    for i,x in enumerate(xs):
        D[(i,j)]=depth(sd(x,z))
def dep(x,z):
    fx=(x-xs[0])/P; fz=(z-zs[0])/P; i=int(fx); j=int(fz); u=fx-i; v=fz-j
    g=lambda a,b: D.get((a,b),0)
    if u+v<=1: return g(i,j)+u*(g(i+1,j)-g(i,j))+v*(g(i,j+1)-g(i,j))
    return g(i+1,j+1)+(1-u)*(g(i,j+1)-g(i+1,j+1))+(1-v)*(g(i+1,j)-g(i+1,j+1))
p=0.25; andar=nadar=0; mx=0
x=c0[0]-13.5
while x<c0[0]+13.5:
    z=c0[1]-13.5
    while z<c0[1]+13.5:
        f=dep(x,z)
        if f>1.25: nadar+=p*p
        elif f>0: andar+=p*p
        mx=max(mx,f); z+=p
    x+=p
print('andar %.0f nadar %.0f total %.0f max %.2f'%(andar,nadar,andar+nadar,mx))
# casas 1.5 + degrau (bed) 
ca=cn=0; dmax=0
for l in range(50):
    for c in range(50):
        x0=-37.5+c*1.5; z0=-37.5+l*1.5
        if abs(x0+0.75-c0[0])>14 or abs(z0+0.75-c0[1])>14: continue
        f=dep(x0+0.75,z0+0.75)
        if f>1.25: cn+=1
        elif f>0: ca+=1
        if f>0 and f<=1.25:
            vals=[dep(x0+a,z0+b) for a,b in ((0,0),(1.5,0),(0,1.5),(1.5,1.5),(.75,.75))]
            dmax=max(dmax,max(vals)-min(vals))
print('casas andar',ca,'nadar',cn,'degrau max (casas de andar)',round(dmax,2))
