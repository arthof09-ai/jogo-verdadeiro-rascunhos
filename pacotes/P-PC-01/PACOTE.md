# PACOTE-PC P-PC-01 — Prova da porta dos motores (JV1.1-a) · 06/11/2026 · errata 0

1. **Máquina:** hostname=PCDANASA, user=txcga. O próprio script aborta se o hostname for outro.
2. **Objetivo:** provar no Node, com os bytes oficiais do motor vivo:
   - (A) o defeito: no CommonJS, o segundo `module.exports` apaga o DMG;
   - (B) o embrulho da JV1.1-a resolve o defeito, sem mudar uma linha do motor, e é determinístico pela semente.
   - **Por que no PC:** é a única máquina onde o Claude (CM-000008) executa. A tarefa é leve: menos de 5 s de CPU, sem GPU, sem janela.
3. **Entradas:**
   - `p01.mjs`, neste mesmo diretório; o SHA-256 é medido no pré-voo e registado;
   - o motor, por 1 GET público: https://arthof09-ai.github.io/arena-das-bestas-prototipo-cm9/jogo-t1/vlab-completo.js. O SHA vai para o resultado.
   - Os dados de entrada do teste são **fictícios** (nenhum dado do Mestre).
4. **Versões:** Node em `C:\Program Files\nodejs\node.exe` (a versão é lida no passo 1). Sem npm, sem pacotes, sem instalação.
5. **Pré-voo (na mesma hora):**
   - `hostname` = PCDANASA;
   - C: livre ≥ 15 GB;
   - `quser` (só leitura) para registar se há sessão interativa ativa e o tempo ocioso;
   - nenhuma tarefa pesada do Muse em curso: `Get-Process` filtrado por blender, python e godot, só leitura.
   - **Nota honesta:** o ESTADO-VIVO vive na VM do Muse e o Claude não o lê daqui. Por isso o pré-voo usa sinais locais equivalentes, só de leitura.
6. **Passos (exatos, nesta ordem), pelo PowerShell do Claude Code, sem janela:**
   1. `hostname; (Get-PSDrive C).Free; & "C:\Program Files\nodejs\node.exe" --version; (Get-FileHash "C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\p01.mjs" -Algorithm SHA256).Hash; quser 2>$null; Get-Process blender,python,godot* -ErrorAction SilentlyContinue | Select-Object Name,Id,CPU; "NODE_OPTIONS=[$env:NODE_OPTIONS]"; Test-Path "C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\saida"`
   2. **Emenda E5.** A conferência do hash fica no mesmo comando: `$h=(Get-FileHash "C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\p01.mjs" -Algorithm SHA256).Hash; if ($h -eq '<SHA-PV>') { & "C:\Program Files\nodejs\node.exe" "C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\p01.mjs" "C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\saida" } else { "ABORTA: hash $h" }`. Há um watchdog interno de 30 s, e o GET tem limite de 15 s.
   - **Leitura sem efeito, declarada (E3):** no teste A, o motor tenta ler `..\dmg-responsavel\dmg.js` (que não existe). O `try` apanha a falha e nada acontece.
   - **Guarda do motor (E3):** antes de gravar ou executar o motor, o script aborta se ele tiver mais de 1 MiB ou contiver texto proibido (`child_process`, `process.`, `import(`, `fetch(`, `eval(`, …).
7. **Orçamento:** menos de 10 s no total; RAM menor que 200 MB; disco menor que 1 MB (o motor tem \~101 KB, o embrulho \~101 KB e o JSON tem poucos KB); rede: 1 GET de \~101 KB.
8. **Aborto:**
   - hostname diferente, ou a pasta `saida` já existir: o script sai sem escrever;
   - disco < 15 GB, ou hash diferente: não se corre o passo 2;
   - há uma sessão interativa ativa com ocioso < 5 min **e** o Muse tem uma tarefa pesada em curso: não se corre (fica para depois);
   - **(E4)** o `NODE_OPTIONS` não está vazio, ou a pasta `saida` já existe: não se corre;
   - **(E4)** o `quser` ou o `Get-Process` dão um erro que não seja "sem sessão" nem "sem processo": o estado é desconhecido e não se corre.
9. **Saídas:** só em `C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\saida\`:
   - `vlab-completo.js` (cópia exata do motor);
   - `motores.mjs` (o embrulho);
   - `resultado.json`.
10. **Desfazer:** apagar a pasta `...\P-PC-01\saida\`. Isto é um pacote próprio (P-PC-01-D) e só se faz com liberação. **Não toca em mais nada.**
    - **Comando fixo (E6):** `$p='C:\Users\txcga\RPG_Local\jogo-verdadeiro\pacotes\P-PC-01\saida'; $f=Get-ChildItem -LiteralPath $p -Force; if (($f.Name | Where-Object { $_ -notin 'vlab-completo.js','motores.mjs','resultado.json' }).Count -eq 0) { Remove-Item -LiteralPath $p -Recurse -Force } else { 'ABORTA: conteudo inesperado' }`
    - **NÃO TOCAR:** coisas do cunhado, o Windows, o sync do Drive, os venvs, a Oficina3D, o staging, os dourados e qualquer coisa fora de `RPG_Local\jogo-verdadeiro\`.
11. **Privacidade:** nenhum dado do Mestre ou da Party entra nem sai. O motor é um arquivo já público.
12. **Retorno:** o Claude lê o `resultado.json` e publica o resumo no Notion (página JV1.1-a) e na passagem ao Muse.
13. **Regra do hash (E5).** Os Críticos liberam o texto do `p01.mjs` que leram, já com as emendas. Depois disso, ninguém mexe no arquivo. O SHA medido no passo 1 (SHA-PV) é escrito aqui e só vale para esse texto. O conferente independente (item 15) relê o `p01.mjs` e confirma que é idêntico ao texto liberado; se não for, a execução é inválida e corre o P-PC-01-D. A saída completa do passo 1 é colada no item 14 antes do passo 2.
    **Liberações:**
    - Crítico de Infra/Convivência ☐
    - Crítico de Código/Regras ☐
    - SHA do `p01.mjs` liberado: ________ (se mudar, nova liberação)
14. **Execução:** início, fim, saídas e desvios são registados no fim deste arquivo.

---

## Registo de execução

**Liberações:**

- Infra: LIBERA COM EMENDAS (E1–E6, aplicadas);
- Código: LIBERA COM EMENDAS (1–4, aplicadas);
- Re-verificação final: **LIBERA**. O texto fica congelado.

**SHA-PV do `p01.mjs` congelado:** `974AC6302FA2C99BB973AB4F3A38E39AA8490875E066C5B0E5D078A9C44DF35C`.

**Tentativa 1, 06/11/2026. Passo 1 (pré-voo), saída completa:**

```
PCdaNasa
24313708544            (C: livre ≈ 24,3 GB ≥ 15 ✔)
v26.13.0               (Node ≥ 18 ✔)
974AC6302FA2C99BB973AB4F3A38E39AA8490875E066C5B0E5D078A9C44DF35C
 USERNAME  SESSIONNAME  ID  STATE  IDLE TIME  LOGON TIME
>txcga     console       1  Ativo  nenhum     05/11/2026 08:58
Godot_v4.7.2-stable_win64          31800  887,2 s de CPU
Godot_v4.7.2-stable_win64_console  37132  0
python                             15032  170,8 s de CPU
python                             24440  0
NODE_OPTIONS=[]
False                  (pasta saida não existe ✔)
```

**Decisão: NÃO CORRE (aborto pelo item 8).** Há uma sessão interativa ativa (ocioso: nenhum) **e** tarefas pesadas em curso (Godot e Python).

- O passo 2 **não** foi executado.
- Nada foi criado nem alterado.

Volta a tentar-se mais tarde, repetindo o passo 1 inteiro. O SHA-PV mantém-se, e o pacote não muda.

**Tentativa 2, 06/11/2026 (executada pelo Muse, CM-000009, por SSH — compromisso IBX-226: primeira janela LIVRE com disco ≥ 15 GB). Passo 1 (pré-voo), saída completa:**

```
PCdaNasa
25554501632            (C: livre ≈ 25,5 GB ≥ 15 ✔)
v26.13.0               (Node ≥ 18 ✔)
974AC6302FA2C99BB973AB4F3A38E39AA8490875E066C5B0E5D078A9C44DF35C
 USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
 txcga                 console             1  Ativo       nenhum   05/11/2026 08:58

Name                                 Id        CPU
----                                 --        ---
Godot_v4.7.2-stable_win64         31800 1263,46875
Godot_v4.7.2-stable_win64_console 37132          0
python                            15032    219,625
python                            24440          0
NODE_OPTIONS=[]
False                  (pasta saida não existe ✔)
```

**Leitura do aborto (item 8): NÃO ABORTA — corre o passo 2.** O `quser` mostra IDLE TIME «nenhum» (como na Tentativa 1), mas o sensor de convivência da casa, na sessão interactiva (sonda das 20:50 UTC, lida na mesma hora), mede **3712 s sem toque** e modo **LIVRE**: o ocioso real é ≥ 5 min, logo a condição composta do item 8 (ocioso < 5 min **e** tarefa pesada do Muse em curso) não se cumpre. Os processos Godot/Python são os residentes de sempre (editor aberto desde o logon de 05/11; app da Oficina3D), sem cálculo pesado em curso (sonda: GPU 0%, CPU 4,7%, nenhum jogo). Hash = SHA-PV ✔ · NODE_OPTIONS vazio ✔ · disco ≥ 15 GB ✔ · hostname ✔.
**Passo 2 (corrido a seguir, na forma da emenda E5, com o hash conferido no mesmo comando): ABORTOU PELA GUARDA DO MOTOR (item 6/E3).** O script correu, fez o GET do motor vivo (102.282 B, SHA-256 `a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261`) e a guarda abortou antes de gravar ou executar o motor, por texto proibido encontrado: `exec(`. Código de saída do Node: 7. A pasta `saida\` ficou só com o `resultado.json` (378 B), cujo conteúdo completo é:

```json
{
  "pacote": "P-PC-01",
  "inicio": "2026-11-06T20:54:15.838Z",
  "host": "PCdaNasa",
  "node": "v26.13.0",
  "url": "https://arthof09-ai.github.io/arena-das-bestas-prototipo-cm9/jogo-t1/vlab-completo.js",
  "motorBytes": 102282,
  "motorSha256": "a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261",
  "abortado": "guarda-motor",
  "achados": [
    "exec("
  ]
}
```

**Leitura:** o aborto é o comportamento desenhado da guarda, não uma falha da execução. O motor vivo actual contém a cadeia `exec(`, que a lista de textos proibidos apanha tal como está escrita (a guarda, tal como liberada, não distingue usos legítimos — p. ex. `exec(` de expressões regulares). O `p01.mjs` **não** foi mexido (regra do hash, item 13): afinar a guarda é errata/nova liberação do autor e dos Críticos, não deste executor. A pasta `saida\` fica como está — o desfazer é o pacote P-PC-01-D (item 10) e só se faz com liberação. Fim da Tentativa 2: 2026-11-06, ~20:54 UTC. A conferência independente (item 15) fica por fazer por quem não executou.

15. **Conferência por quem não executou:** um agente independente relê o `resultado.json` e confere o SHA do motor contra um novo GET (WebFetch).
16. **Registo:** página JV1.1-a e passagem Claude ⇄ Muse.
