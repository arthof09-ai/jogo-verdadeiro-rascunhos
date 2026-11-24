# Provas — ORDEM-SONDA-CAMINHOS-PC

Nenhum ficheiro desta pasta traz o caminho do PC escrito. As formas são montadas em tempo de execução. A própria
Sonda nova corre sobre esta pasta e dá 0 ocorrências novas.

**A rede cobre as três formas pedidas pela ordem; não cobre todos os caminhos reais do PC.**

| ficheiro | o que é |
|---|---|
| `remendo-privacidade.yml.patch` | os dois passos novos do `privacidade.yml`. **Está por aplicar:** o token do PC não tem o âmbito `workflow` (ver o ESTADO-FINAL §3) |
| `ferramentas/prova-sonda.sh` | a prova local: corre os passos do `privacidade.yml` + remendo na cópia de trabalho, sem e com um ficheiro de teste por forma |
| `logs/p0-sem-formas.log` | o ramo tal como está: e-mails limpos, caminhos 348/348 na base, 0 novos → **saída 0** |
| `logs/p1-forma-1.log` | ficheiro de teste com a forma 1 (unidade C + barra) na linha 2 → apanhado, **saída 1** |
| `logs/p2-forma-2.log` | o mesmo com a forma 2 (unidade C + barra invertida) → **saída 1** |
| `logs/p3-forma-3.log` | o mesmo com a forma 3 (Git Bash, `/c/` + `Users/`) → **saída 1** |
| `logs/p4-depois.log` | ficheiro de teste apagado → **saída 0** outra vez |
| `logs/p5-auto-teste.log` | o passo «A rede morde» do CI: 11 casos, 0 falhas |
| `suites/servidor.log` | `rascunhos/servidor`: 442/442 |
| `suites/validador-glb.log` | `rascunhos/validador-glb`: 31 passam, 2 saltados (os do UAL1, sem `UAL1_GLB`, como no CI), 0 falhas |
| `suites/rodar_testes.log` | `rascunhos/cliente`, Godot 4.7.2 `--headless`: 333 de 333 |

Para repetir (na raiz do repositório): `bash provas/ordem-sonda-caminhos-pc/ferramentas/prova-sonda.sh <python>`.
