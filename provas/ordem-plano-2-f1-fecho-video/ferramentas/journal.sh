#!/bin/bash
cd "<JV>/ordem-plano-2-f1-fecho-video-pc/repo/bancada-rede/privado" && node -e '
const j=JSON.parse(require("fs").readFileSync("registo-MESTRE-ONLY-bancada-rede.json","utf8")); const r=JSON.parse(String(j.registo).split("\n")[0]); const e=r.estado;
const nm=(id)=>e.figuras[id]?.nomePublico??id;
console.log("fase",e.fase,"rodada",e.rodada,"vez",nm(e.vez?.figuraId),"desfecho",JSON.stringify(e.desfecho),"eventos",r.eventos.length);
for (const f of Object.values(e.figuras)) console.log(" ",nm(f.id),"vida",f.vidaActual,"pos",f.x,f.y,"paGasto",f.paGasto,"caido",f.caido,"vivo",f.vivo,JSON.stringify(f.estadoMorte));
for (const x of r.eventos.filter(x=>!["ia"].includes(x.tipo)).slice(-'${1:-8}')) {const d={...x.dados}; for (const k of ["atacanteId","alvoId","autorId","figuraId"]) if (d[k]) d[k]=nm(d[k]); console.log("  ",x.journalSeq,x.ts.slice(11,22),x.tipo,JSON.stringify(d).slice(0,220), x.soMestre?.recibo? "| "+x.soMestre.recibo : "");}'
