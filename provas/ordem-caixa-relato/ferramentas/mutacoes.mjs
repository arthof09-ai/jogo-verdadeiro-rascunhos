// Ordem CAIXA-RELATO-CORRECOES-3 (B7): as mutações das provas da caixa, por escrito — cada uma é um conjunto de
// substituições EXACTAS (cada texto tem de aparecer uma vez só no ficheiro, senão a mutação recusa-se) e o que se
// corre a seguir (o teste do relato, a prova HUD ou a prova MANEQUIM). Quem aplica e repõe é correr-mutacoes.sh.
//
//   node mutacoes.mjs lista <base|novo>          → «id corrida» por linha
//   node mutacoes.mjs aplicar <base|novo> <id>   → aplica a mutação (na raiz do repo)
//
// `base` = os ficheiros da base (fable/integracao-50 6a87b9e, o código da CAIXA-RELATO-CORRECOES-2): as 6 mutações da
// ordem anterior (B1, B2, B3 ×3, B5, B6), para os números dela terem registo, e as novas para mostrar que a base não as
// apanhava. `novo` = o código desta ordem.
import { readFileSync, writeFileSync } from 'node:fs';

const PROVA_HUD = 'provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd';
const PROVA_MAN = 'provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd';
const RELATO = 'provas/ordem-caixa-relato/ferramentas/relato_caixa.gd';
const TESTE = 'provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd';
const FICHAS = 'rascunhos/servidor/autojogo/fichas-bancada.json';

const ORIGEM = 'return "ROOM_SNAPSHOT seq %s';
const fuga = (txt) => ({ f: RELATO, de: ORIGEM, para: 'return "' + txt + ' ROOM_SNAPSHOT seq %s' });
const RESUMO_HUD = '"prova da caixa no HUD da jogadora: %d de %d verificações passaram."';
const RESUMO_MAN = '"prova da caixa com os manequins: %d de %d verificações passaram."';
const NOME_PUB = 'var np = f.get("nomePublico")';
const TEXTOS = '_textos(_arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem"), textos)';
// Simula um aparelho em UTC para o caso da hora do teste: a hora «local do sistema» do teste passa a ser a UTC.
const UTC_NO_TESTE = { f: TESTE, todas: true, de: 'Time.get_time_string_from_system()', para: 'Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system()))' };
// A espadachim (a jogadora que entra) ganha um nome público diferente do nome — um cenário com heroína nome ≠ nomePublico.
const FICHA_PUB = { f: FICHAS, de: '"nomePublico": "Espadachim de Bancada",', para: '"nomePublico": "Espadachim",', json: true };

const comuns = {
  // ---- as 6 da ordem anterior (CAIXA-RELATO-CORRECOES-2)
  'B1-nome-verdadeiro': { corrida: 'hud', subs: [{ f: PROVA_HUD, de: NOME_PUB, para: 'var np = f.get("nome")' }],
    diz: 'CORRECOES-2 B1: `_nome_publico` lê o `nome` (o verdadeiro) — o relato traz «Bruto de Bancada»' },
  'B2-fuga-linhas-hora': { corrida: 'teste', subs: [{ f: RELATO, de: ORIGEM, para: 'return ("nome " if _num(snap.get("seq")) == "13" else "") + "ROOM_SNAPSHOT seq %s' }],
    diz: 'CORRECOES-2 B2: uma fuga «nome » só nas linhas de seq 13 (as do caso da hora)' },
  'B3-caixaMestre': { corrida: 'teste', subs: [fuga('(caixaMestre)')], diz: 'CORRECOES-2 B3: «(caixaMestre)» na origem da linha' },
  'B3-master': { corrida: 'teste', subs: [fuga('(master)')], diz: 'CORRECOES-2 B3: «(master)» na origem da linha' },
  'B3-PA': { corrida: 'teste', subs: [fuga('(PA 3)')], diz: 'CORRECOES-2 B3: «(PA 3)» na origem da linha' },
  'B6-estado-de-actor': { corrida: 'teste',
    subs: [{ f: RELATO, de: 'if OrdemTurnos.actor_do_evento(evento) != "":', para: 'if OrdemTurnos.actor_do_evento(evento) != "" or str(evento.get("tipo")) == "estado":' }],
    diz: 'CORRECOES-2 B6: `anotar_evento` conta o `estado` como de actor' },
  // ---- as desta ordem
  'N-B2-canario-minusculas-relato': { corrida: 'hud',
    subs: [{ f: PROVA_HUD, de: 'return str(np) if np is String and np != "" else id', para: 'return str(f.get("nome", "")).to_lower() if np is String and np != "" else id' }],
    diz: 'CORRECOES-3 B2: o relato traz o nome verdadeiro em minúsculas («bruto de bancada»)' },
  'N-B2-canario-minusculas-caixa': { corrida: 'hud',
    subs: [{ f: PROVA_HUD, de: TEXTOS, para: TEXTOS + '\n\ttextos.append(str(canarios.filter(func(k): return not str(k).is_valid_int())[0]).to_lower())' }],
    diz: 'CORRECOES-3 B2: um texto da caixa traz o nome verdadeiro em minúsculas' },
  'N-B3-heroina-nome-publico-hud': { corrida: 'hud', subs: [FICHA_PUB],
    diz: 'CORRECOES-3 B3: cenário com a heroína que entra com nome ≠ nomePublico («Espadachim de Bancada» / «Espadachim») — sem mutação de código' },
  'N-B3-heroina-nome-publico-manequim': { corrida: 'manequim', subs: [FICHA_PUB],
    diz: 'CORRECOES-3 B3: o mesmo cenário — manequim' },
  'N-B6-utc-e-sem-fuso': { corrida: 'teste', subs: [UTC_NO_TESTE],
    diz: 'CORRECOES-3 B6: o caso do CI — aparelho em UTC (simulado no teste) e `hora_ms()` sem o fuso' },
};

const porModo = {
  base: {
    ...comuns,
    'B5-bias-zero': { corrida: 'teste', subs: [{ f: RELATO, de: 'int(Time.get_time_zone_from_system().get("bias", 0)) * 60', para: '0 * 60' }],
      diz: 'CORRECOES-2 B5: `hora_ms()` esquece o fuso (bias → 0)' },
    'N-B1-canario-na-linha-em-branco': { corrida: 'hud', subs: [{ f: PROVA_HUD, de: '\t_linha("")\n', para: '\t_linha(str(_canarios_nomes[0]))\n' }],
      diz: 'CORRECOES-3 B1: a linha em branco final traz um canário' },
    'N-B1-canario-no-resumo-hud': { corrida: 'hud',
      subs: [{ f: PROVA_HUD, de: RESUMO_HUD + ' % [_total - _falhas, _total])', para: RESUMO_HUD + ' % [_total - _falhas, _total] + " " + str(_canarios_nomes[0]))' }],
      diz: 'CORRECOES-3 B1: a última linha do relato (o resumo) traz um canário' },
    'N-B1-canario-no-resumo-manequim': { corrida: 'manequim',
      subs: [{ f: PROVA_MAN, de: RESUMO_MAN + ' % [_total - _falhas, _total])', para: RESUMO_MAN + ' % [_total - _falhas, _total] + " " + str(_canarios_nomes[0]))' }],
      diz: 'CORRECOES-3 B1: a última linha do relato (o resumo) traz um canário — manequim' },
  },
  novo: {
    ...comuns,
    'B5-bias-zero': { corrida: 'teste', subs: [{ f: RELATO, de: 'var local := int(floor(t)) + bias * 60', para: 'var local := int(floor(t)) + 0 * 60' }],
      diz: 'CORRECOES-2 B5: `hora_ms()` esquece o fuso (bias → 0)' },
    'N-B1-canario-na-linha-em-branco': { corrida: 'hud', subs: [{ f: PROVA_HUD, de: '\t_linha("")\n\t_linha(resumo', para: '\t_linha(str(_canarios_nomes[0]))\n\t_linha(resumo' }],
      diz: 'CORRECOES-3 B1: a linha em branco final traz um canário (só a escrita; a pré-varredura não o vê — apanha-o a re-varredura)' },
    'N-B1-canario-no-resumo-hud': { corrida: 'hud',
      subs: [{ f: PROVA_HUD, de: 'var resumo := ' + RESUMO_HUD, para: 'var resumo := ' + RESUMO_HUD + ' + " " + (str(_canarios_nomes[0]) if not _canarios_nomes.is_empty() else "")' }],
      diz: 'CORRECOES-3 B1: a última linha do relato (o resumo) traz um canário' },
    'N-B1-canario-no-resumo-manequim': { corrida: 'manequim',
      subs: [{ f: PROVA_MAN, de: 'var resumo := ' + RESUMO_MAN, para: 'var resumo := ' + RESUMO_MAN + ' + " " + (str(_canarios_nomes[0]) if not _canarios_nomes.is_empty() else "")' }],
      diz: 'CORRECOES-3 B1: a última linha do relato (o resumo) traz um canário — manequim' },
  },
};
// O caso do CI junta o aparelho em UTC à mutação do fuso (o texto do fuso é o de cada modo).
for (const m of Object.values(porModo)) m['N-B6-utc-e-sem-fuso'] = { ...m['N-B6-utc-e-sem-fuso'], subs: [UTC_NO_TESTE, ...m['B5-bias-zero'].subs] };

const [cmd, modo, id] = process.argv.slice(2);
const tab = porModo[modo];
if (!tab) { console.error('modo: base | novo'); process.exit(2); }
if (cmd === 'lista') {
  for (const [k, v] of Object.entries(tab)) console.log(k + ' ' + v.corrida);
} else if (cmd === 'diz') {
  console.log(tab[id].diz);
} else if (cmd === 'ficheiros') {
  console.log([...new Set(tab[id].subs.map((s) => s.f))].join('\n'));
} else if (cmd === 'aplicar') {
  const m = tab[id];
  if (!m) { console.error('mutação desconhecida: ' + id); process.exit(2); }
  for (const s of m.subs) {
    let txt = readFileSync(s.f, 'utf8').replace(/\r\n/g, '\n');
    const n = txt.split(s.de).length - 1;
    if (n === 0 || (n > 1 && !s.todas)) { console.error(`${id}: «${s.de}» aparece ${n}× em ${s.f}`); process.exit(3); }
    txt = txt.split(s.de).join(s.para);
    if (s.json) JSON.parse(txt);
    writeFileSync(s.f, txt);
  }
} else { console.error('comando: lista | diz | ficheiros | aplicar'); process.exit(2); }
