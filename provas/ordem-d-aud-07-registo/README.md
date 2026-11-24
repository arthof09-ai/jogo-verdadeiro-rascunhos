# Provas — ORDEM-D-AUD-07-REGISTO (o rótulo do Registo do Mestre diz quem fez a jogada)

Linha `fable/integracao-50`. Código em `5208fb0`; listas da retoma em `38170f6`. PC, Windows 11, Node do PC,
Godot 4.7.2-stable (win64), Python 3.12 (jsonschema 4.26.0) para o `conferir-schemas.py`.

## O defeito, reproduzido e corrigido (captura do Registo)

`capturas/` — a aba **Registo** do ecrã do Mestre, desenhada pelo cliente real a partir da **vista real do
servidor** (`vista-mestre.json`, gerada por `ferramentas/gerar-vista-registo.mjs`: servidor real, motor falso, IA em
«auto»; a heroína encerra, a IA do orc joga e encerra, a heroína encerra outra vez — a reprodução da auditoria `r-40`
e da INVESTIGA `l30`).

| foto | o que é |
|---|---|
| `registo-antes.png` | a mesma vista **sem** `autorId`/`rodadaAutor` — o cliente cai no rótulo de antes desta ordem (rodada/vez **depois** da transacção). Vê-se o defeito: «Rodada 2 · vez de Heroína Teste · Ação do monstro, vez nova» e os encerrar da heroína como «vez de Orc…» |
| `registo-depois.png` | a vista como o servidor a manda hoje: «Rodada 1 · vez de Orc Verdadeiro Teste 1 (Orc 1) · Ação do monstro, vez nova»; os dois encerrar da heroína dizem «vez de Heroína Teste» (rodadas 1 e 2) |

O texto de cada linha, das duas fotos, está em `logs/capturar_registo.log` (8/8 verificações: o defeito aparece no
«antes», desaparece no «depois», e as linhas certas estão lá). A janela de 1280×720 sai a 1028 px de largura no ecrã
deste PC e o bordo direito da coluna do Registo fica cortado (o layout do Mestre é mais largo do que a janela — é o
D-AUD-14, fora desta ordem); o log tem o texto inteiro.

Comandos (da raiz do clone):

    node provas/ordem-d-aud-07-registo/ferramentas/gerar-vista-registo.mjs provas/ordem-d-aud-07-registo/capturas/vista-mestre.json
    cd rascunhos/cliente && godot --path . --resolution 1280x720 -s <raiz>/provas/ordem-d-aud-07-registo/ferramentas/capturar_registo.gd \
        -- --vista=<raiz>/provas/ordem-d-aud-07-registo/capturas/vista-mestre.json --saida=<raiz>/provas/ordem-d-aud-07-registo/capturas

`logs/gerar-vista-registo.log` lista cada ponto com o estado **depois** (`rodada`/`vezId`) e o **autor**
(`rodadaAutor`/`autorId`). O ponto `#14 [ia,turno]` é o caso da auditoria: depois = rodada 2, vez da heroína;
autor = rodada 1, o orc.

## Contraprova por mutação

`logs/mutacao-rotulo-depois.log` — com o `guardarCheckpoint` a pôr no `autorId`/`rodadaAutor` o estado **depois**
(o rótulo de antes), o teste novo `d-aud-07-registo.test.mjs` cai em 3 dos 4 testes (o 4.º é o de privacidade, que não
depende do valor). Reposto o código, 4/4. Os caminhos do PC no log estão trocados por `<clone>/`.

## Suites (todas no código `5208fb0`)

| suite | resultado | log |
|---|---|---|
| servidor, `node --test --test-isolation=none "testes/*.test.mjs"` | **446/446** (4 novos) | `logs/servidor-testes.log` |
| tráfego dos testes do servidor contra os schemas (`conferir-schemas.py`) | 0 falhas nas mensagens que saem; 64 mensagens com `rodadaAutor` validadas | `logs/protocolo-conferir-schemas.log` |
| `pecas_mestre.gd` | **329/329** (4 novas: «rótulo do Registo: quem fez a jogada») | `logs/cliente-pecas_mestre.log` |
| `rodar_testes.gd` | 333/333 | `logs/cliente-rodar_testes.log` |
| `abrir_scripts.gd` | 112 scripts, 0 falhas | `logs/cliente-abrir_scripts.log` |
| `abrir_mestre.gd` | 67/67 | `logs/cliente-abrir_mestre.log` |
| `medir_mestre.gd` | 0 falhas, 0 sem medida | `logs/cliente-medir_mestre.log` |
| `medir_painel_config.gd` | 0 falhas, 0 sem medida | `logs/cliente-medir_painel_config.log` |
| `hud_acoes.gd` | 50/50 | `logs/cliente-hud_acoes.log` |
| `caixa_jogadora.gd` | 70/70 | `logs/cliente-caixa_jogadora.log` |
| `caixa_janela.gd` | 123/123 | `logs/cliente-caixa_janela.log` |
| `canario_privacidade.gd` | 10/10 | `logs/cliente-canario_privacidade.log` |
| `teste_relato_caixa.gd` (provas/ordem-caixa-relato) | 31/31 | `logs/cliente-teste_relato_caixa.log` |
| `teste_nomes_relato.gd` (provas/ordem-caixa-janela) | 26/26 | `logs/cliente-teste_nomes_relato.log` |
| e2e: servidor real + jogadora (Node) + Mestre (Godot), motor falso | Mestre 17/17; jogadora OK, nenhum canário do Mestre | `logs/e2e-*.log` |

O CI (Testes dos rascunhos + Sonda de privacidade) fica na nota do fim do `ESTADO-FINAL-ORDEM-D-AUD-07-REGISTO.md`.
