// conferir-terreno.mjs — Ordem 48 (parte C). A CONFERÊNCIA COMPLETA do terreno do servidor, num só comando.
//
//   node rascunhos/servidor/ferramentas/conferir-terreno.mjs [--godot=<caminho do Godot 4.7>]
//
// Duas conferências, por esta ordem:
//   1. as FONTES (rápida, só Node): o SHA de cada ficheiro de que o terreno depende (texto com fins de linha LF) tem de
//      ser o que vai no cabeçalho do pacote (dados/terreno-floresta.json). É a mesma guarda do rodar_testes do CI;
//   2. o PACOTE (completa, com o Godot): refaz o pacote inteiro com o exportador do cliente
//      (cliente/cenas/arena/ferramentas/exportar_terreno.gd -- --conferir: abre a arena do jogo 10 vezes, ~40 s) e
//      compara-o, byte a byte, com o do repositório. Não escreve nada.
// Sai com 0 e «TERRENO EM DIA» se as duas passam. Senão sai com 1 e o porquê, nomeado:
//   TERRENO_DESACTUALIZADO   uma fonte mudou sem se reexportar, ou o pacote difere do que o cliente gera hoje
//                            (diz que fontes e que partes do pacote);
//   GODOT_NAO_ENCONTRADO     não há Godot para a conferência completa (a das fontes corre na mesma e diz-se);
//   GODOT_FALHOU             o Godot não chegou ao fim (o código e as últimas linhas).
// O Godot procura-se por esta ordem: --godot=…, a variável GODOT, `godot` no PATH, e por fim
// ~/godot-*/Godot_v4.7*.exe (a bancada do PCDANASA). O CI não corre isto (só a guarda das fontes, no rodar_testes).
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { homedir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const CLIENTE = path.resolve(AQUI, '../../cliente');
const PACOTE = path.resolve(AQUI, '../dados/terreno-floresta.json');
const EXPORTADOR = 'res://cenas/arena/ferramentas/exportar_terreno.gd';

const falhas = [];
const dizer = (t) => process.stdout.write(t + '\n');

// ---------------------------------------------------------------- 1. as fontes
function conferirFontes() {
  let pacote;
  try {
    pacote = JSON.parse(readFileSync(PACOTE, 'utf8'));
  } catch (e) {
    falhas.push(`TERRENO_DESACTUALIZADO: o pacote ${PACOTE} não se lê (${e.code ?? e.message})`);
    return;
  }
  const fontes = pacote?.cabecalho?.fontes ?? {};
  // A lista das fontes é a do exportador (FONTES); lê-se de lá para não haver duas listas.
  const exportador = readFileSync(path.join(CLIENTE, EXPORTADOR.replace('res://', '')), 'utf8');
  const bloco = exportador.match(/const FONTES := \[([^\]]*)\]/);
  const lista = bloco ? [...bloco[1].matchAll(/"res:\/\/([^"]+)"/g)].map((m) => m[1]) : [];
  if (!lista.length) {
    falhas.push('TERRENO_DESACTUALIZADO: não encontrei a lista FONTES no exportador');
    return;
  }
  const mudadas = [];
  for (const f of lista) {
    const texto = readFileSync(path.join(CLIENTE, f), 'utf8').replace(/\r\n/g, '\n');
    const sha = createHash('sha256').update(texto, 'utf8').digest('hex');
    if (fontes[f] !== sha) mudadas.push(f);
  }
  const aMais = Object.keys(fontes).filter((f) => !lista.includes(f));
  if (mudadas.length || aMais.length) {
    falhas.push(`TERRENO_DESACTUALIZADO: ${[...mudadas.map((f) => `a fonte ${f} mudou desde a exportação`),
      ...aMais.map((f) => `a fonte ${f} já não conta`)].join('; ')}`);
  } else {
    dizer(`fontes: ${lista.length} em dia com o pacote (${lista.join(', ')})`);
  }
}

// ---------------------------------------------------------------- 2. o pacote, refeito pelo cliente
function acharGodot() {
  const arg = process.argv.find((a) => a.startsWith('--godot='));
  if (arg) return arg.slice('--godot='.length);
  if (process.env.GODOT) return process.env.GODOT;
  for (const nome of ['godot', 'godot4']) {
    const r = spawnSync(nome, ['--version'], { encoding: 'utf8' });
    if (r.status === 0) return nome;
  }
  const casa = homedir();
  for (const pasta of readdirSync(casa).filter((n) => /^godot-/i.test(n)).sort().reverse()) {
    let ficheiros = [];
    try {
      ficheiros = readdirSync(path.join(casa, pasta));
    } catch {
      continue;
    }
    // a consola primeiro (escreve no terminal), depois a normal
    const exe = ficheiros.filter((n) => /^Godot_v4\.7.*\.exe$/i.test(n)).sort((a, b) => Number(b.includes('console')) - Number(a.includes('console')))[0];
    if (exe && existsSync(path.join(casa, pasta, exe))) return path.join(casa, pasta, exe);
  }
  return null;
}

function conferirPacote() {
  const godot = acharGodot();
  if (!godot) {
    falhas.push('GODOT_NAO_ENCONTRADO: a conferência completa precisa do Godot 4.7 (--godot=…, GODOT, ou godot no PATH)');
    return;
  }
  dizer(`pacote: a refazer com ${godot} (abre a arena do jogo 10 vezes, ~40 s)…`);
  const r = spawnSync(godot, ['--headless', '--path', CLIENTE, '-s', EXPORTADOR, '--', '--conferir'], { encoding: 'utf8', maxBuffer: 64 << 20 });
  const linhas = `${r.stdout ?? ''}\n${r.stderr ?? ''}`.split(/\r?\n/).filter((l) => l.trim() && !l.startsWith('[floresta]'));
  const relatorio = [];
  let dentro = false;
  for (const l of linhas) {
    if (/^(terreno do servidor EM DIA|TERRENO_DESACTUALIZADO)/.test(l)) dentro = true;
    if (dentro) relatorio.push(l);
  }
  if (r.status === 0 && relatorio.some((l) => l.startsWith('terreno do servidor EM DIA'))) {
    dizer('pacote: refeito pelo cliente, igual byte a byte ao do repositório');
    return;
  }
  if (relatorio.some((l) => l.startsWith('TERRENO_DESACTUALIZADO'))) {
    falhas.push(relatorio.join('\n'));
    return;
  }
  falhas.push(`GODOT_FALHOU: o exportador saiu com ${r.status ?? r.error?.code ?? '?'}\n${linhas.slice(-15).join('\n')}`);
}

conferirFontes();
conferirPacote();
if (falhas.length) {
  dizer('');
  for (const f of falhas) dizer(f);
  if (!falhas.some((f) => f.includes('refazer: '))) {
    dizer('\nrefazer: (em rascunhos/) godot --headless --path cliente -s res://cenas/arena/ferramentas/exportar_terreno.gd');
  }
  process.exit(1);
}
dizer('TERRENO EM DIA');
