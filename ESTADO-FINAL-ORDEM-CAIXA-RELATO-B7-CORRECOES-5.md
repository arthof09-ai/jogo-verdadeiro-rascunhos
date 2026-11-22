# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-5

As correcções B1–B6 da sentença da conferência da CAIXA-RELATO-B7-CORRECOES-4. O **PIN de bancada foi rodado primeiro**,
e só depois saíram do ramo os ficheiros com o antigo. **Nada do código do jogo mudou:** em `rascunhos/` só mudou a linha
`"pin"` do `cenario-bancada.json`, que a ordem pede.

- **Executor:** conta 1, no PC.
- **Base:** `6148f79`, a ponta de `fable/integracao-50` à hora do lançamento. Na hora do push ainda era a ponta.
- **Ramo:** `claude1/caixa-relato-b7-correcoes-5`, **sem fusão**.
- **Commits:**
  - `de02d81`: B1–B6, o script de mutações novo, o README e as corridas;
  - `974a264`: as listas da retoma (`actualizar-listas`), que mudam por causa do cenário;
  - o commit deste ESTADO-FINAL, que só junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/` não existe). Trabalhei pelo texto da ordem e conferi
  cada afirmação contra as fontes.
- **Privacidade:** o valor do PIN novo não aparece neste ficheiro, em nenhum registo cometido nem em nenhuma mensagem.
  Todas as verificações abaixo dão só contagens.

As pastas abaixo são relativas a `provas/ordem-caixa-relato/`, salvo se disser outra coisa.

## 1. Ponto a ponto

### B1 (D1, ALTA) — rodar o PIN, depois apagar

**Feito, nesta ordem: rodar primeiro, apagar depois.**

1. **Rodar.** Gerei um valor novo com `/dev/urandom` e escrevi-o sem o imprimir.
   - **Tem 20 dígitos.** O primeiro não é zero, não é uma data e não é curto.
   - **Tem de ser só de dígitos.** A ordem sugeria 12 ou mais caracteres alfanuméricos, mas a sala recusa-os: o
     `criarSala` exige `/^\d{6,}$/` para o PIN do Mestre (E-P9, `rascunhos/servidor/nucleo/sala.js:341`) e lança
     `TypeError`. O código do servidor está fora do meu território. Um número aleatório de 20 dígitos tem cerca de 66
     bits, mais do que 12 alfanuméricos em minúsculas (cerca de 62).
   - **Onde está:** só nos 5 ficheiros pedidos, em 6 ocorrências: `rascunhos/servidor/autojogo/cenario-bancada.json:7` e
     o `var _pin := …` dos 4 `.gd`. Esses são `prova_caixa_jogadora.gd`, `prova_caixa_janela.gd`,
     `prova_caixa_manequim.gd` e `prova_caixa_reentrar.gd`; este último tem também o exemplo `--pin=` do cabeçalho.
   - **O servidor aceita-o:** a forma E-P9 dá `true`. As duas provas vivas desta ordem entraram como Mestre com ele,
     com 43/43 e 53/53 (ver §2).
2. **Apagar.** Saíram do ramo **58 ficheiros**: 29 `servidor-info.json` e 29 `servidor.log`, em
   `provas/ordem-caixa*/…`.
   - **58, e não 54:** a contagem do coordenador (27 + 27) é de antes de a base avançar. A `6148f79` já traz mais as
     pastas `cobertura-correcoes-3/` e `cobertura-correcoes-4/` da CAIXA-JANELA, com 1 info e 1 log cada.
   - Apaguei todos os ficheiros seguidos que tinham o valor antigo e não eram os 5 da rotação. Era sempre um
     `servidor-info.json` ou um `servidor.log` (conferido: 0 outros).
   - Nenhum manifesto, lista, teste ou workflow os referia (conferido por grep). Os README dessas ordens ainda os citam,
     como registo histórico.
3. **A verificação por grep** está em `b7-correcoes-5/verificacao-pin.log`:

| Na árvore do ramo (`git grep`, fora do histórico) | Ficheiros |
|---|---|
| com o PIN antigo¹ | **0** |
| com o PIN novo | **5** (os pedidos), 6 ocorrências |
| registos de `b7-correcoes-5/` com o PIN novo | **0** |
| registos de `b7-correcoes-5/` com uma chave `"pin":` | **0** |
| `servidor-info.json` seguidos | **0** |

O histórico do git fica com o valor antigo, como a ordem aceita. Esse valor já não abre a sala de bancada.

¹ *Emenda da Ordem CAIXA-RELATO-B7-CORRECOES-6 (B3):* esta linha e a linha 3 do `verificacao-pin.log` escreviam o PIN
antigo por extenso, contra a letra da ordem — e, por isso, a contagem «0» era falsa: este ficheiro e o log tinham-no.
O valor saiu dos dois; com ele saído, a contagem bate. O PIN novo de 20 dígitos destas tabelas também já não está
no ramo: a CAIXA-RELATO-B7-CORRECOES-6 tirou-o dos 5 ficheiros (o PIN passa a ser gerado por corrida).

### B2 (D2) — a pasta temporária nos logs das mutações

**Feito, no script novo `ferramentas/correr-mutacoes-b7-correcoes-5.sh`.** O da B7-CORRECOES-4 fica como estava, porque é
o registo dessa ordem. As mutações e os esperados são os mesmos 34.

- **Cada log é limpo logo a seguir à corrida.** A pasta `mktemp` passa a `<tmp>` nas três grafias: a do Git Bash, a de
  `cygpath -m` (a que o Godot escreve) e a de `cygpath -w`. A troca não distingue maiúsculas.
- **No fim, o script confere.** Se algum log da saída ainda trouxer a pasta temporária, a casa (`$HOME`, nas duas
  grafias) ou o nome do utilizador, sai com **6**.
- **Executado:** os 2 logs da `b1-fechada-numero` levam agora `<tmp>/novo/_mutacao_teste.gd:…`, com 20 trocas em cada um.
  Os ficheiros de `b7-correcoes-5/` com o nome do utilizador ou com `AppData` são **0**, e o `mutacoes.log` termina com
  `logs com caminho pessoal: 0`.
- **Os 2 logs da B7-CORRECOES-4 ficam como estavam:** são registo dessa ordem, e o padrão antigo dos outros 36 ficheiros
  foi aceite pela sentença.

### B3 (D3) — o lançador já não imprime o PIN

**Feito** em `ferramentas/correr-prova-caixa-relato.sh`. A linha `cat "$T/info-$1.json"` (a 29 na base) deu lugar a um
`node -e` que imprime o info **sem a chave `"pin"`**. O motor, o SHA do cenário e o das fichas continuam a sair.

- **Antes:** o info de cada corrida tinha 1 chave `"pin"`, e o `cat` punha-a no stdout.
- **Depois:** o stdout do lançador desta corrida tem **0** chaves `"pin"` e **0** vezes o valor novo.
- O registo está em `b7-correcoes-5/antes/b3-lancador.log`, só com contagens.

### B4 (D4) — os argumentos

**Feito.** O número de argumentos e o `<godot>` validam-se antes do `cd`. A base valida-se logo a seguir ao `cd`,
porque o git precisa da raiz do repositório. Tudo isto acontece antes de se criar qualquer pasta. *(Emenda da
CAIXA-RELATO-B7-CORRECOES-6, B4: a frase dizia que os argumentos todos se validavam antes do `cd`.)* O registo está em
`b7-correcoes-5/antes/b4-argumentos.log`.

| Chamada | Script da -4 | Script da -5 |
|---|---|---|
| sem argumentos | **rc=1** | **rc=2**, e o uso no stderr |
| só um argumento | **rc=1** | **rc=2** |
| `<godot>` que não existe | — | **rc=2** |
| base que o git não conhece | — | **rc=3** |
| argumentos a mais (5) | — | **rc=2** |

### B5 (D5) — Godot que morre a meio

**Feito.** Uma corrida só conta se tiver chegado ao fim. Isso falha quando:

- o código do Godot é diferente de 0 e de 1 (por exemplo 124 do `timeout` ou 141 de SIGPIPE);
- o filtro do log sai com mais de 1;
- o log fica vazio;
- falta a linha «N de M verificações passaram».

Nesses casos, a linha do `mutacoes.log` diz `FALHA-DA-CORRIDA (motivo)` e não conta como BATE nem como NAO-BATE. O script
sai com **4**, que tem precedência sobre o 6 e o 1. O código 4 está dentro dos 2–9 que o cabeçalho promete.

Reproduzi-o com dois Godot falsos, ambos fora do repositório. O registo está em `b7-correcoes-5/antes/b5-*.log`:

| Godot falso | Script da -4 | Script da -5 |
|---|---|---|
| `morre-124`: escreve 3 linhas e sai com 124 | rc=1, **34 NAO-BATE** | **rc=4, 34 FALHA-DA-CORRIDA** («o Godot saiu com 124») |
| `corta`: o Godot verdadeiro, com o log cortado às 12 linhas e rc=1 | rc=1, 21 NAO-BATE e **13 BATE falsos** | **rc=4, 34 FALHA-DA-CORRIDA** («sem a linha «N de M…»») |

A segunda linha mostra um defeito mais grave do que o descrito na sentença. Com um log truncado e um código «normal»,
o script antigo chegava a dar **BATE** a corridas que não chegaram ao fim, porque «0 ecos» num log cortado parece o
resultado certo. O script novo apanha esse caso pela linha do resumo. Verifiquei antes que todas as 34 corridas reais a
escrevem.

Por decisão da sentença, a correcção do separador não-ASCII (a mutação `b5-separador-nao-ascii`, da B7-CORRECOES-4)
regista-se como parte da B5. Nesta corrida continua a dar o esperado: o teste novo dá 30/31 com 0 ecos, e o antigo
31/31 com 1 eco.

### B6 (D6 + D7) — os dois números do ESTADO-FINAL da B7-CORRECOES-4

**Feito** em `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-4.md`:

- **Tabela B1, linha `"ordem": [a, "dinamico"]`, teste antigo:** passa de 8 para **2 ecos¹**. A nota de rodapé diz que
  na primeira corrida foram 8, com o canário `"turno"]`, que também sai nos tipos dos eventos. Conferido nos registos
  dessa ordem: `b4-codigo-de-saida-1.log` tem `canário=8` e `mutacoes/mutacoes.log` tem `canário=2`. A corrida desta
  ordem também dá 2.
- **Ponto 5:** passa de 36 para **38 ficheiros** em `provas/` com o caminho da casa do PC. Conferi-o na base `6148f79`:
  são 38. Hoje continuam 38, porque nenhum dos 58 ficheiros apagados pela B1 o trazia e nenhum ficheiro desta ordem o
  traz.

## 2. Corridas

Corri tudo neste PC, sobre a árvore de `de02d81`. Usei o Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`), o motor
VLAB real (sha256 `a91c021c…3261`) e a semente 7. O cenário tem agora o sha256 `2cab6459…`, porque o PIN mudou; as
fichas continuam `3c498137…`. Os registos estão em `b7-correcoes-5/`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`) | **31/31**, código 0 | `teste-relato.log` |
| Prova viva HUD-JOGADORA (`prova_caixa_jogadora.gd`), com o PIN novo | **43/43**, código 0, 68 linhas | `cliente-hud/relato.txt` |
| Prova viva MANEQUIM (`prova_caixa_manequim.gd`), com o PIN novo | **53/53**, código 0, 78 linhas | `cliente-manequim/relato.txt` |
| Mutações (34 corridas: 16 do teste novo, 16 do antigo e 2 do r1), script novo | **34/34 batem**, 0 FALHA-DA-CORRIDA, 0 logs com caminho pessoal, código 0 | `mutacoes/mutacoes.log` |
| Testes do servidor (`rascunhos/servidor/testes/*.test.mjs`), por causa do cenário | **420/420** | — |
| `prova-servidor.mjs` da caixa | `PROVA OK` | — |

- **As provas vivas dão os mesmos números de `b7-correcoes-4/`:** 43/43 em 68 linhas e 53/53 em 78. Só mudou o PIN com
  que o Mestre entra.
- **As mutações dão, linha a linha, os mesmos resultados de `b7-correcoes-4/mutacoes/mutacoes.log`:** o mesmo código,
  o mesmo «N de M», os mesmos FALHA/RETIDA e os mesmos ecos (diff vazio, tirando os espaços). O script novo junta 2
  linhas no fim: as falhas da corrida e os logs com caminho pessoal.
- **Com o `conferir-registo.mjs`, iguais aos da B7-CORRECOES-4:**
  - `mutacoes.log`: 0 achados;
  - `teste-relato.log`: 2 achados, o falso positivo antigo da linha 38;
  - relatos vivos: 48 e 46 achados, que são os nomes públicos curtos.
- **`actualizar-listas`:** corri-o depois de `de02d81`. Dá `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros
  (0 novos, 0 tirados)`. Mudou só a linha do `cenario-bancada.json` no `MANIFESTO-SHA256.txt` e no
  `retoma-i0004/depois.txt` (`7703320c…` → `2cab6459…`). As listas foram no commit `974a264`, e o registo está em
  `b7-correcoes-5/actualizar-listas.log`.
- **O lançador** recebeu a pasta de saída em caminho absoluto. As capturas, o info e o log do servidor ficaram na pasta
  tmp da sede.

## 3. CI

**Verde em `974a264`** (a ponta com as correcções e as listas):

- **Testes dos rascunhos** (run 45018895081): **10/10 jobs**, a saber protocolo, validador-glb, cliente, motor-real,
  provas-mapa, godot-cliente, ponta-a-ponta, **retoma-pc**, foto-mestre e servidor.
- **Sonda de privacidade** (run 45018895049): success.
- **No registo do CI:**
  - teste do relato: `teste do relato da caixa: 31 de 31 verificações passaram.`;
  - servidor: 420 testes, 420 passaram;
  - prova da caixa do servidor: `PROVA OK`;
  - retoma-pc: `FEITO: 415 ficheiros no PC iguais ao ramo (SHA conferido).`, com o cenário novo.

O CI do commit deste ESTADO-FINAL, que só junta este ficheiro, corre a seguir ao push. Antes desse commit voltei a
correr o `actualizar-listas`, e não mudou nada.

## 4. Pontos para o coordenador

1. **O PIN novo é numérico, e não alfanumérico.** A sala só aceita dígitos para o Mestre (`sala.js:341`, E-P9). Usei 20
   dígitos aleatórios. Para aceitar alfanuméricos, teria de mudar o servidor, com outra ordem e outro território.
2. **O PIN novo também fica público quando o ramo for publicado.** Está no cenário e nos 4 `.gd`, como a ordem manda, e
   o repositório é público. A protecção continua a ser o `127.0.0.1` e a sala efémera. Agora já não é adivinhável e não
   está espalhado por 58 registos. Se se quiser que nem isso fique no repositório, o caminho é o lançador gerar um PIN
   por corrida e passá-lo por `--pin=`, que os 4 `.gd` já aceitam. O servidor de bancada lê-o hoje do cenário. É uma
   ordem à parte.
3. **58 ficheiros apagados, e não 54:** a base avançou duas ordens da CAIXA-JANELA desde a contagem.
4. **Três lançadores fora do meu território ainda copiam o PIN** (conferido por grep): `correr-prova-caixa-hud.sh`,
   `correr-prova-caixa-janela.sh` e `correr-prova-caixa-manequim.sh`.
   - Fazem `cat "$T/info.json"` para o stdout.
   - Fazem `cp` do info e do log do servidor para `$S/servidor-info.json` e `$S/servidor.log`, a pasta que se comete.
   - Não lhes mexi. Se voltarem a correr, trazem o PIN novo para o ramo. A CAIXA-JANELA é a que mais corre.
   - Vale a pena aplicar-lhes a B3 da B7-CORRECOES-4 e a desta ordem numa ordem própria, de preferência antes da próxima
     corrida da CAIXA-JANELA.
5. **A B5 apanhou mais do que a sentença descrevia.** Um log truncado com rc=1 dava BATE falso no script antigo (13 em
   34 no ensaio). O script da B7-CORRECOES-4 fica como registo, mas os resultados dele só são fiáveis com logs
   completos. Os 34 logs dessa ordem têm todos a linha do resumo, por isso os números que deu valem.
6. **Os valores nos logs são canários de bancada, fictícios,** os mesmos da B7-CORRECOES-4.
7. **A fronteira:** mudaram só `provas/ordem-caixa-relato/`, a linha `"pin"` do cenário, a linha `_pin` dos 4 `.gd` (e o
   exemplo do cabeçalho do `prova_caixa_reentrar.gd`), os 58 apagados, o ESTADO-FINAL da -4 (B6), as listas da retoma e
   este ficheiro. Não toquei no código do jogo, no HUD, nas cores nem no workflow.
8. **Não mexi no `ORDEM.md` da sede**, como nas ordens anteriores. A linha «Estado: NOVA» já lá está, e a marca de
   estado é tua.
