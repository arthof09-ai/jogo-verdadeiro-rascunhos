import json,math
d=json.load(open('dump.json'))
N=d['nivel']; H=d['h38']; P=0.75
def h38(x,z):
    fx=(x-0)/P; fz=(z+42)/P
    i=int(fx); j=int(fz); u=fx-i; v=fz-j
    a=H[j][i]; b=H[j][i+1]; c=H[j+1][i]; e=H[j+1][i+1]
    return a*(1-u)*(1-v)+b*u*(1-v)+c*(1-u)*v+e*u*v
trilho=[(-4.0,-12.5),(5.0,-13.5),(12.0,-8.5),(20.5,-3.5),(29.0,0.5),(39.0,2.5)]
obs=[(t[0],t[1],t[2]+1.3) for t in d['troncos'] if not (abs(t[0]-24.4)<0.1)]
obs+=[(r[0],r[1],r[2]*0.9+0.7) for r in d['rochas']]
def segd(p,a,b):
    ax,az=a;bx,bz=b;px,pz=p
    t=max(0,min(1,((px-ax)*(bx-ax)+(pz-az)*(bz-az))/((bx-ax)**2+(bz-az)**2)))
    return math.hypot(px-ax-t*(bx-ax),pz-az-t*(bz-az))
def ok(x,z):
    if x>35.0 or z<-35.5 or x<2: return False
    for (ox,oz,r) in obs:
        if math.hypot(x-ox,z-oz)<r: return False
    for k in range(len(trilho)-1):
        if segd((x,z),trilho[k],trilho[k+1])<3.2: return False
    return True
import sys
c0=(float(sys.argv[1]),float(sys.argv[2])) if len(sys.argv)>2 else (19.5,-19.0)
rm=[]
for k in range(72):
    a=2*math.pi*k/72
    r=0
    while r<20 and ok(c0[0]+math.sin(a)*r, c0[1]-math.cos(a)*r): r+=0.1
    rm.append(r)
print(' '.join('%d:%.1f'%(k*5,r) for k,r in enumerate(rm)))
# area of the star polygon
A=sum(0.5*r*r*(2*math.pi/72) for r in rm); print('area max',round(A))
for R in (6,8,10,12,14):
    print(R,' '.join('%.1f'%(h38(c0[0]+math.sin(2*math.pi*k/24)*R,c0[1]-math.cos(2*math.pi*k/24)*R)-N) for k in range(24)))
