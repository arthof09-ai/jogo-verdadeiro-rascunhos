# uso: python pix.py figura|marcadores ...   (lê PNG via ffmpeg -> rgb24 cru)
import subprocess, sys, json
FF = r'<JV>\ordem-plano-2-f1-pc\tmp\ffmpeg.exe'
def rgb(p):
    pr = subprocess.run([FF,'-hide_banner','-loglevel','error','-i',p,'-f','rawvideo','-pix_fmt','rgb24','-'],capture_output=True,check=True)
    out = subprocess.run([FF,'-hide_banner','-i',p],capture_output=True,text=True).stderr
    import re; w,h = map(int, re.search(r', (\d+)x(\d+)', out.split('Video:')[1]).groups())
    return w,h,pr.stdout
def figura(p):
    # a figura da jogadora: cápsula azul saturada (B alto, R baixo); fora da caixa (canto de cima à direita) e da barra de baixo
    w,h,b = rgb(p); xs=[];ys=[]
    for y in range(120,650):
        o=y*w*3
        for x in range(0,975 if y<170 else w):
            r,g,bb=b[o+3*x],b[o+3*x+1],b[o+3*x+2]
            if bb>140 and bb-max(r,g)>50: xs.append(x); ys.append(y)
    if not xs: return {'ficheiro':p,'px':0}
    xs.sort(); ys.sort(); n=len(xs); cx=xs[n//2]; cy=ys[n//2]
    return {'ficheiro':p,'px':n,'centro':[cx,cy],'caixa':[xs[int(n*.02)],ys[int(n*.02)],xs[int(n*.98)],ys[int(n*.98)]],
            'terco_central':[w/3,h/3,2*w/3,2*h/3],'dentro': w/3<=cx<=2*w/3 and h/3<=cy<=2*h/3,'w':w,'h':h}
def marcadores(com, sem):
    # diferença entre a captura com os anéis (modo Ataque) e a mesma vista sem eles; vermelho vivo novo = marcador
    w,h,a = rgb(com); _,_,s = rgb(sem); pts=[]
    for y in range(150,640):
        for x in range(0,960):
            i=(y*w+x)*3; r,g,bb=a[i],a[i+1],a[i+2]; r0,g0,b0=s[i],s[i+1],s[i+2]
            if r>180 and g<110 and bb<110 and (abs(r-r0)+abs(g-g0)+abs(bb-b0))>60: pts.append((x,y))
    # agrupar por proximidade (componentes simples por grelha de 4 px)
    grupos=[]
    for x,y in pts:
        for gr in grupos:
            if gr[0]-12<=x<=gr[2]+12 and gr[1]-12<=y<=gr[3]+12:
                gr[0]=min(gr[0],x);gr[1]=min(gr[1],y);gr[2]=max(gr[2],x);gr[3]=max(gr[3],y);gr[4]+=1;break
        else: grupos.append([x,y,x,y,1])
    grupos=[g for g in grupos if g[4]>=30]
    return {'com':com,'sem':sem,'marcadores':[{'caixa':g[:4],'largura_px':g[2]-g[0]+1,'altura_px':g[3]-g[1]+1,'pixeis':g[4]} for g in grupos]}
if __name__=='__main__':
    if sys.argv[1]=='figura':
        for p in sys.argv[2:]: print(json.dumps(figura(p),ensure_ascii=False))
    else: print(json.dumps(marcadores(sys.argv[2],sys.argv[3]),ensure_ascii=False))
