// Relato COMPLETO de um journal da bancada (todas as seqs), com cada conta conferida.
// uso: node relato.mjs <registo-MESTRE-ONLY-bancada-rede.json> <fichas.json> "<título>" > relato.md
import fs from "node:fs";
import crypto from "node:crypto";

const [, , caminho, caminhoFichas, titulo] = process.argv;
const bruto = fs.readFileSync(caminho);
const j = JSON.parse(bruto.toString("utf8"));
const r = JSON.parse(String(j.registo).split("\n")[0]);
const ev = r.eventos;
const fichas = JSON.parse(fs.readFileSync(caminhoFichas, "utf8")).fichas;
const est = r.estado;

const nomes = {}; for (const x of ev) if (x.tipo === "colocacao") nomes[x.dados.figuraId] = x.dados.nomePublico;
const nome = (id) => nomes[id] ?? est.figuras[id]?.nomePublico ?? id;
const ficha = (id) => { const f = est.figuras[id]; return fichas.find((x) => x.id === (f?.fichaId ?? f?.ficha)) ?? fichas.find((x) => x.nome && nome(id) && x.nome.startsWith(nome(id).replace(/ \d+$/, ""))); };
const tec = (fid, arma) => (fichas.find((x) => x.id === fid)?.tecnicas ?? []).find((t) => t.id === arma);
const fichaIdDe = (id) => est.figuras[id]?.fichaId ?? "?";
const fichaDe = (id) => fichas.find((x) => x.id === fichaIdDe(id));
const man = (a, b) => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
const che = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
const intervalo = (expr) => { const m = /^(\d+)d(\d+)\+(\d+)$/.exec(expr); const n = +m[1], l = +m[2], b = +m[3]; return { min: n + b, max: n * l + b, maxDados: n * l }; };
const hora = (ts) => ts.slice(11, 23);
const esc = (s) => String(s).replace(/\|/g, "\\|");

const pos = {}, vida = {}, morte = {};
const linhas = [], notas = [];
let ok = 0, falhas = 0;
const confere = (cond, txt) => { if (cond) { ok++; return `✔ ${txt}`; } falhas++; return `✘ ${txt}`; };
const regs = { colocacoes: [], movimentos: [], ataques: [], duasFaces: [], criticos: [], testesMorte: [] };
let ultimoAtaque = null;

for (const x of ev) {
  const d = x.dados ?? {}, s = x.soMestre ?? {};
  let resumo = "", recibo = "", conf = "";
  switch (x.tipo) {
    case "lobby": resumo = "lobby"; break;
    case "colocacao": {
      pos[d.figuraId] = { x: d.x, y: d.y };
      const fc = fichaDe(d.figuraId); vida[d.figuraId] = fc?.vidaTotal ?? null;
      regs.colocacoes.push({ id: d.figuraId, nome: d.nomePublico, x: d.x, y: d.y });
      resumo = `${d.nomePublico} (${d.lado}) em (${d.x},${d.y}), id ${d.figuraId}`;
      conf = `vida inicial ${vida[d.figuraId]} (ficha ${fc?.id})`;
      break;
    }
    case "entrada": resumo = `${d.nomePublico} entra (${d.lado})`; break;
    case "turno": resumo = `vez de ${nome(d.figuraId)} · rodada ${d.rodada}${d.narra ? " · narrada pelo Mestre (criatura; `narra: true`)" : ""}`; break;
    case "ia": {
      const a = s.acao ?? {};
      resumo = `IA de ${nome(d.figuraId)}: ${a.tipo}${a.destino ? ` → (${a.destino.x},${a.destino.y})` : ""}${a.alvoId ? ` → ${nome(a.alvoId)}` : ""} — «${s.razao ?? ""}»`;
      break;
    }
    case "movimento": {
      const c = d.caminho; const passos = c.length - 1;
      const ortog = c.slice(1).every((p, i) => man(p, c[i]) === 1);
      const de = d.de, para = d.para, mh = man(de, para);
      const antes = pos[d.figuraId];
      resumo = `${nome(d.figuraId)} (${de.x},${de.y})→(${para.x},${para.y}) por ${c.map((p) => `(${p.x},${p.y})`).join("")}, ${d.custoM} m, reserva ${d.reservaM} m`;
      conf = [
        confere(antes && antes.x === de.x && antes.y === de.y, `«de» = posição conhecida (${antes?.x},${antes?.y})`),
        confere(ortog, `${passos} passo(s), todos ortogonais de 1 casa`),
        confere(Math.abs(d.custoM - passos * 1.5) < 1e-9, `custo = ${passos} × 1,5 m = ${passos * 1.5} m`),
        mh === passos ? confere(true, `Manhattan (${de.x},${de.y})–(${para.x},${para.y}) = ${mh} = passos (caminho mínimo)`) : `ℹ Manhattan (${de.x},${de.y})–(${para.x},${para.y}) = ${mh} < ${passos} passos: o caminho dá a volta (${(passos - mh)} casa(s) a mais)`,
      ].join("; ");
      regs.movimentos.push({ seq: x.journalSeq, nome: nome(d.figuraId), de, para, passos, mh, custo: d.custoM });
      pos[d.figuraId] = { x: para.x, y: para.y };
      break;
    }
    case "ataque": {
      const at = d.atacanteId, al = d.alvoId; const t = tec(fichaIdDe(at), d.arma); const fAl = fichaDe(al);
      const ctx = s.contexto ?? {}; const niv = (ctx.niveisVantagem | 0) - (ctx.niveisDesvantagem | 0);
      recibo = s.recibo ?? "";
      const m = /→ (.+?) = (\d+) vs CA (\d+) → (\w+)(?: · dano (\d+))?/.exec(recibo);
      const conjuntos = m[1].split(" | ").map((q) => JSON.parse(q));
      const bonus = +/\+(\d+)$/.exec(t.expressaoAtaque)[1];
      const totais = conjuntos.map((c) => c.reduce((a, b) => a + b, 0) + bonus + 2 * niv);
      const total = niv > 0 ? Math.max(...totais) : niv < 0 ? Math.min(...totais) : totais[0];
      const vc = s.verificacaoCritico ?? ctx.verificacaoCritico; const crit = vc && vc[0] === 6 && vc[1] === 6 && vc[2] >= 5;
      const falhaCrit = vc && vc[0] === 1 && vc[1] === 1 && vc[2] <= 2;
      const ca = fAl.ca; const acerta = crit || total > ca;
      const esperado = falhaCrit ? "falhaCritica" : crit ? "critico" : acerta ? "acerto" : "erro";
      const dist = pos[at] && pos[al] ? `Manhattan ${man(pos[at], pos[al])}, Chebyshev ${che(pos[at], pos[al])} entre (${pos[at].x},${pos[at].y}) e (${pos[al].x},${pos[al].y})` : "posições desconhecidas";
      resumo = `${nome(at)} → ${nome(al)} (${d.arma}${d.ataqueDeOportunidade ? ", de oportunidade" : ""}): ${d.resultado}`;
      const partes = [
        confere(t && t.expressaoAtaque === (d.expressao ?? t.expressaoAtaque), `expressão ${t.expressaoAtaque} (ficha ${fichaIdDe(at)})`),
        confere(conjuntos.length === 1 + Math.abs(niv), `${conjuntos.length} conjunto(s) = 1 + |vantagem líquida ${niv}|`),
      ];
      if (conjuntos.length > 1) {
        partes.push(confere(total === +m[2], `duas faces: ${conjuntos.map((c, i) => `[${c}] + ${bonus} (bónus da ficha) + ${2 * niv} (vantagem ${niv} × 2) = ${totais[i]}`).join(" e ")}; fica o ${niv > 0 ? "maior" : "menor"} = ${total}`));
        regs.duasFaces.push({ seq: x.journalSeq, atacante: nome(at), conjuntos, bonus, niv, totais, total, recibo, razao: ctx.ataqueDeOportunidade ? "ataque de oportunidade (sala.js: niveisVantagem 1)" : "?" });
      } else {
        partes.push(confere(total === +m[2], `total ${conjuntos[0]} + ${bonus}${niv ? ` + ${2 * niv}` : ""} = ${total}`));
      }
      partes.push(confere(ca === +m[3], `CA do alvo ${ca} (ficha ${fAl.id})`));
      partes.push(confere(esperado === d.resultado, `verificação do crítico [${vc}] → ${crit ? "6,6 e 3.º ≥ 5: CRÍTICO" : falhaCrit ? "1,1 e 3.º ≤ 2: falha crítica" : "não é crítico"}; ${crit ? "o crítico força o acerto" : `${total} ${total > ca ? ">" : "≤"} ${ca}`} → ${esperado}`));
      if (m[5]) {
        const iv = intervalo(t.expressaoDano); const rd = fAl.rd?.geral ?? 0;
        const min = Math.max(0, iv.min + (crit ? iv.maxDados : 0) - rd), max = iv.max + (crit ? iv.maxDados : 0) - rd;
        partes.push(confere(+m[5] >= min && +m[5] <= max, `dano ${m[5]} dentro de ${t.expressaoDano}${crit ? ` + ${iv.maxDados} (máximo dos dados, crítico)` : ""}${rd ? ` − RD ${rd}` : ""} = [${min}, ${max}]`));
        if (s.totalEfectivo != null) partes.push(confere(s.totalEfectivo === +m[5], `totalEfectivo ${s.totalEfectivo} = dano do recibo`));
      }
      partes.push(`ℹ distância ${dist}`);
      conf = partes.join("; ");
      if (crit) regs.criticos.push({ seq: x.journalSeq, vc, recibo });
      regs.ataques.push({ seq: x.journalSeq, at: nome(at), al: nome(al), resultado: d.resultado, man: pos[at] && pos[al] ? man(pos[at], pos[al]) : null, che: pos[at] && pos[al] ? che(pos[at], pos[al]) : null, ao: d.ataqueDeOportunidade });
      ultimoAtaque = { alvo: al, dano: m[5] ? +m[5] : 0, alvoDepois: s.soDoMestre?.alvoDepois };
      break;
    }
    case "dano": {
      resumo = `${nome(d.alvoId)} perde ${d.valor} (${(d.tipos ?? []).join(",")}) — autor ${nome(d.autorId)}`;
      const antes = vida[d.alvoId]; const depois = Math.max(0, antes - d.valor);
      conf = confere(ultimoAtaque && ultimoAtaque.alvo === d.alvoId && ultimoAtaque.dano === d.valor, `= dano do ataque anterior`) + `; vida ${antes} − ${d.valor} = ${antes - d.valor}${antes - d.valor < 0 ? " → 0 (trava em 0)" : ""}`;
      vida[d.alvoId] = depois;
      const em = morte[d.alvoId];
      if (em && em.fase === "aMorrer" && d.valor > 0) { morte[d.alvoId] = { ...em, falhas: em.falhas + 1 }; conf += `; ℹ dano directo a quem está «aMorrer»: +1 falha (${em.falhas}→${em.falhas + 1}), regra T1`; }
      else if (em && em.fase === "estabilizado" && d.valor > 0) { morte[d.alvoId] = { fase: "aMorrer", sucessos: 0, falhas: 0 }; conf += `; ℹ estabilizada ferida outra vez: reentra a 0/0 (T1)`; }
      break;
    }
    case "estado": {
      const id = d.figuraId;
      resumo = `${nome(id)}: ${d.visivel ?? ""}${d.vidaActual != null ? ` · vida ${d.vidaActual}` : ""}${d.estadoMorte ? ` · estadoMorte ${JSON.stringify(d.estadoMorte)}` : ""}`;
      const c = [];
      if (d.vidaActual != null) { c.push(confere(d.vidaActual === vida[id] || (vida[id] === null), `vida ${d.vidaActual} = conta corrente ${vida[id]}`)); vida[id] = d.vidaActual; }
      if (d.visivel === "morta") c.push(d.estadoMorte ? confere(d.estadoMorte.falhas >= 3, `3 falhas nos testes de morte → morta`) : confere(vida[id] === 0, `figura sem testes de morte designados: vida 0 → morta`));
      if (d.estadoMorte) {
        const a = morte[id]; const n = d.estadoMorte;
        if (!a) c.push(confere(n.falhas === 0 && n.sucessos === 0, `nascimento da corrida de morte 0/0 (vida a 0)`));
        else if (n.fase === "aMorrer" && a.fase === "estabilizado") c.push(confere(n.falhas === 0 && n.sucessos === 0, `estabilizada ferida outra vez: reentra a 0/0 (T1)`));
        else if (n.falhas === a.falhas + 1 && n.sucessos === a.sucessos) c.push(`ℹ +1 falha (${a.falhas}→${n.falhas})`);
        else if (n.sucessos === a.sucessos + 1 && n.falhas === a.falhas) c.push(`ℹ +1 sucesso (${a.sucessos}→${n.sucessos})`);
        else c.push(confere(a.fase === n.fase && a.falhas === n.falhas && a.sucessos === n.sucessos, `estadoMorte igual à conta corrente ${a.fase} ${a.sucessos}✓/${a.falhas}✗`));
        morte[id] = n;
      }
      conf = c.join("; ");
      break;
    }
    case "teste_morte": {
      const sa = s.saida ?? {}; const te = sa.teste ?? {}; const face = te.conjuntos?.[0]?.[0];
      const fc = fichaDe(d.figuraId); const k = { bronze: 3, prata: 6, ouro: 10, ouroNegro: 13, lendario: 20 }[fc.classificacao];
      const cd = fc.constituicao + k; const tot = face + fc.constituicao; const suc = tot > cd;
      resumo = `teste de morte de ${nome(d.figuraId)}: d20 [${face}] → ${sa.publico?.recibo ?? ""} · ${JSON.stringify(sa.estadoMorte)}`;
      recibo = sa.publico?.recibo ?? "";
      conf = [
        confere(te.total === tot, `total = d20 ${face} + CON ${fc.constituicao} = ${tot}`),
        confere(sa.cd === cd, `CD = CON ${fc.constituicao} + k ${k} (${fc.classificacao}) = ${cd}`),
        confere(sa.sucesso === suc, `${tot} ${suc ? ">" : "≤"} ${cd} → ${suc ? "sucesso" : "falha"} (o d20 tem de ser ≥ ${k + 1})`),
      ].join("; ");
      regs.testesMorte.push({ seq: x.journalSeq, face, tot, cd, suc, depois: sa.estadoMorte, desfecho: sa.desfecho });
      const a0 = morte[d.figuraId];
      if (a0) { const esp = { ...a0, sucessos: a0.sucessos + (suc ? 1 : 0), falhas: a0.falhas + (suc ? 0 : 1) }; conf += "; " + confere(esp.sucessos === sa.estadoMorte.sucessos && esp.falhas === sa.estadoMorte.falhas, `progressão ${a0.sucessos}✓/${a0.falhas}✗ → ${sa.estadoMorte.sucessos}✓/${sa.estadoMorte.falhas}✗`); }
      if (sa.estabilizado) { vida[d.figuraId] = 1; conf += "; ℹ 3 sucessos → estabilizada: fica caída com 1 de Vida (Q4, sala.js:792)"; }
      if (sa.estadoMorte) morte[d.figuraId] = sa.estadoMorte;
      break;
    }
    case "fim": resumo = `fim ${JSON.stringify(d)}`; break;
    default: resumo = JSON.stringify(d);
  }
  linhas.push(`| ${x.journalSeq} | ${hora(x.ts)} | ${x.tipo} | ${esc(resumo)} | ${esc(recibo)} | ${esc(conf)} |`);
}

const ids = regs.colocacoes.map((c) => c.id), casas = regs.colocacoes.map((c) => `${c.x},${c.y}`);
const idsRep = ids.length - new Set(ids).size, casasRep = casas.length - new Set(casas).size;
const seqs = ev.map((x) => x.journalSeq); const buracos = [];
for (let i = 1; i <= Math.max(...seqs); i++) if (!seqs.includes(i)) buracos.push(i);
const fim = ev.find((x) => x.tipo === "fim");

const out = [];
out.push(`# ${titulo}`, "");
out.push(`Fonte: \`${caminho.replace(/.*[\\/]/, "")}\` (cópia bruta neste pacote: \`journal/\`), SHA-256 \`${crypto.createHash("sha256").update(bruto).digest("hex")}\`. Gerado por \`ferramentas/relato.mjs\` (todas as seqs, sem selecção).`, "");
out.push(`Desfecho: **${fim ? JSON.stringify(fim.dados) : "sem fim"}** (seq ${fim?.journalSeq}) · fase \`${est.fase}\` · rodada ${est.rodada} · ${ev.length} eventos · seqs 1..${Math.max(...seqs)} ${buracos.length ? `(faltam: ${buracos.join(",")})` : "sem buracos"}`, "");
out.push(`Colocações: ${regs.colocacoes.length} (${regs.colocacoes.map((c) => `${c.nome} em (${c.x},${c.y})`).join("; ")}) · **ids repetidos: ${idsRep}** · **casas repetidas: ${casasRep}**`, "");
out.push(`Conferências automáticas: **${ok} ✔, ${falhas} ✘**.`, "");
out.push("## Regras declaradas (lidas no código que correu)", "");
out.push("- **Crítico** (`vlab-completo.js` D4, `resolverAtaque`; `sala.js:1668`): NÃO sai do d20. O servidor gera à parte uma verificação de 3d6 por CSPRNG (`verificacaoCritico`, só no `soMestre`); é crítico se os dois primeiros forem 6 e o 3.º ≥ 5 − margem (a margem não é enviada: 0, por isso o 3.º tem de ser 5 ou 6). O crítico FORÇA o acerto, seja qual for o total, e o dano soma o máximo dos dados da técnica. Falha crítica = 1,1 e 3.º em {1,2}. Por isso um «[8] = 14 → CRÍTICO» é legítimo, e um «[20]» pode não ser crítico.");
out.push("- **Testes de morte** (`vlab-completo.js` `resolverTesteDeMorte`, M3/T1–T9): só para quem tem testes de morte designados (a Arqueira; os monstros a 0 ficam «morta»). No início de cada vez dela, caída, rola-se a Fortitude: total = d20 + CON (o «+1» da expressão não entra: `bonusFonte: nenhum`) contra CD = CON + k da classificação (bronze: k = 3). Arqueira: CON 11 → CD 14, sucesso se total > 14, ou seja d20 ≥ 4. Sem crítico dentro do teste. Corrida 3×3: 3 sucessos estabilizam (fica caída com 1 de Vida e sem agir até uma cura — Q4, `sala.js:792`), 3 falhas matam. Dano directo enquanto está «aMorrer» soma +1 falha (crítico incluído: +1, nunca +2); estabilizada e ferida outra vez reentra a 0/0.");
out.push("- **Recibos de duas faces** (`vlab-completo.js` D3; `sala.js:2001`): o ataque de oportunidade é resolvido com `niveisVantagem: 1`. Uma vantagem líquida = 2 conjuntos de 1d20, cada um com o bónus da ficha + 2 (= 2 × vantagem); fica o MAIOR. O recibo mostra os dois conjuntos separados por « | ». Cada um está explicado na tabela abaixo.");
out.push("- **Distâncias**: a grelha é de 1,5 m por casa. Cada movimento é conferido passo a passo (ortogonal, 1 casa), custo = passos × 1,5 m, e contra a distância de Manhattan entre a origem e o destino. Nos ataques ficam registadas as distâncias de Manhattan e de Chebyshev entre as figuras naquele momento (os corpo-a-corpo na diagonal dão Manhattan 2 e Chebyshev 1).");
out.push("- **Dano**: o journal não guarda as faces do dano (só a semente). Confere-se que cada dano cai dentro do intervalo da expressão da técnica (+ máximo dos dados no crítico, − RD do alvo).", "");
if (regs.duasFaces.length) {
  out.push("## Os recibos de duas faces", "", "| seq | atacante | recibo | faces | conta | porquê duas |", "|---|---|---|---|---|---|");
  for (const q of regs.duasFaces) out.push(`| ${q.seq} | ${q.atacante} | ${esc(q.recibo)} | ${q.conjuntos.map((c) => `[${c}]`).join(" e ")} | ${q.conjuntos.map((c, i) => `${c}+${q.bonus}+${2 * q.niv}=${q.totais[i]}`).join(" · ")} → maior = ${q.total} | ${q.razao} |`);
  out.push("");
} else out.push("## Os recibos de duas faces", "", "Não há nesta batalha (nenhum ataque com vantagem/desvantagem).", "");
out.push("## Distâncias dos movimentos contra Manhattan", "", "| seq | figura | de → para | passos | Manhattan | custo |", "|---|---|---|---|---|---|");
for (const q of regs.movimentos) out.push(`| ${q.seq} | ${q.nome} | (${q.de.x},${q.de.y}) → (${q.para.x},${q.para.y}) | ${q.passos} | ${q.mh} | ${q.custo} m |`);
out.push("", "## Testes de morte", "", "| seq | d20 | total | CD | resultado | estadoMorte depois | desfecho |", "|---|---|---|---|---|---|---|");
for (const q of regs.testesMorte) out.push(`| ${q.seq} | ${q.face} | ${q.tot} | ${q.cd} | ${q.suc ? "sucesso" : "falha"} | ${JSON.stringify(q.depois)} | ${q.desfecho} |`);
out.push("", "## Estado final das figuras", "", "| figura | vida | vivo | caído | posição | estadoMorte |", "|---|---|---|---|---|---|");
for (const f of Object.values(est.figuras)) out.push(`| ${nome(f.id)} | ${f.vidaActual} | ${f.vivo} | ${f.caido} | (${f.x},${f.y}) | ${JSON.stringify(f.estadoMorte)} |`);
out.push("", "## O journal inteiro (todas as seqs)", "", "| seq | hora (UTC) | evento | resumo | recibo (soMestre) | conferência |", "|---|---|---|---|---|---|", ...linhas, "");
process.stdout.write(out.join("\n"));
process.stderr.write(`ok=${ok} falhas=${falhas} idsRep=${idsRep} casasRep=${casasRep} eventos=${ev.length} buracos=${buracos.length}\n`);
