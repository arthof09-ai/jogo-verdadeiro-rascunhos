# PACOTE-PC P-PC-02 — Testes do núcleo do servidor de mesa (JV1.1–1.4) · 06/11/2026 · errata 0

1. **Máquina:** hostname PCDANASA (o PC devolve `PCdaNasa`; a comparação não distingue maiúsculas), user txcga.

2. **Objetivo:** correr pela primeira vez os 8 arquivos `*.test.mjs` de `rascunhos\servidor\testes\`, para saber o que passa e o que falha.
   - **Não corrige nada:** só mede.
   - **Por que no PC:** é a única máquina onde o Claude executa. A tarefa é leve: só CPU, menos de 60 s, sem janela, sem GPU, sem rede.

3. **Entradas** (código escrito por um agente, nunca executado):
   - o que se executa:
     - `rascunhos\servidor\nucleo\*.js` (util, sha256, carregar-fichas, projecao, journal, sala);
     - `rascunhos\servidor\testes\*.mjs`;
     - `package.json` (`"type":"module"`, sem dependências);
   - os dados: `dados-exemplo\fichas-ficticias.json`, **só fictícios**;
   - **fica de fora:** `adaptadores\node\servidor-ws.js`. Nenhum teste o importa (conferido por Grep), e **não é carregado**.
   - **Conferências feitas por Grep, só leitura:**
     - os testes não contêm `createServer`, `listen(`, `node:http`, `node:net`, `writeFile`, `child_process` nem `fetch(`;
     - os imports `node:*` dos testes são só `node:test`, `node:assert/strict`, `node:fs` (`readFileSync` da fixture) e `node:crypto` (para conferir o SHA puro);
     - o `nucleo\` não importa nada `node:*`.

4. **Versões:** Node v26.13.0, em `C:\Program Files\nodejs\node.exe`. Sem npm e sem instalação.

5. **Jaula (o modelo de permissões do Node):**
   - `--permission` com `--allow-fs-read` **só** sobre a pasta `rascunhos\servidor\`;
   - **sem `--allow-fs-write`**: nenhuma escrita em disco;
   - **sem `--allow-child-process`** e **sem `--allow-worker`**: nenhum processo filho;
   - os testes correm no mesmo processo (`--test-isolation=none`), porque o isolamento padrão lança processos filhos, que a jaula proíbe;
   - **rede (E1):** no Node v26, o `--permission` bloqueia a rede sem `--allow-net`, e o `--allow-net` não é passado. A conferência por Grep (item 3) é a segunda garantia.

6. **Pré-voo** (na mesma hora, só leitura):

   ```
   hostname; (Get-PSDrive C).Free; & "C:\Program Files\nodejs\node.exe" --version; "NODE_OPTIONS=[$env:NODE_OPTIONS]"; quser 2>$null; Get-Process blender,python,godot* -ErrorAction SilentlyContinue | Select-Object Name,Id,CPU; (Get-ChildItem "C:\Users\txcga\RPG_Local\jogo-verdadeiro\rascunhos\servidor" -Recurse -File | Get-FileHash -Algorithm SHA256 | Sort-Object Path | ForEach-Object { $_.Hash + "  " + $_.Path.Substring(60) }) -join "`n"; "V8COV=[$env:NODE_V8_COVERAGE] CCACHE=[$env:NODE_COMPILE_CACHE]"
   ```

   - A lista de SHA do pré-voo é o **SHA-PV do pacote**, e só vale para o texto que os Críticos leram.
   - Um arquivo novo ou alterado depois da liberação torna a execução inválida.

7. **Execução** (um comando; timeout de 120 s na ferramenta):

   **(E4)** O SHA-PV é conferido dentro do próprio comando:

   ```
   $r="C:\Users\txcga\RPG_Local\jogo-verdadeiro\rascunhos\servidor"; $l=(Get-ChildItem $r -Recurse -File | Get-FileHash -Algorithm SHA256 | Sort-Object Path | ForEach-Object { $_.Hash + "  " + $_.Path.Substring(60) }) -join "`n"; $h=[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($l))).Replace('-',''); if ($h -eq '<SHA-PV>') { Set-Location $r; & "C:\Program Files\nodejs\node.exe" --permission --allow-fs-read="C:\Users\txcga\RPG_Local\jogo-verdadeiro\rascunhos\servidor\*" --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" } else { "ABORTA: SHA-PV $h" }
   ```

   O resultado sai só na consola: é capturado pela ferramenta e colado no item 14. **Nada é gravado em disco.**

8. **Orçamento e aborto:**
   - tempo menor que 60 s, RAM menor que 300 MB, disco 0;
   - **aborta** (não corre) se:
     - o hostname for diferente;
     - o C: tiver menos de 15 GB;
     - o `NODE_OPTIONS` não estiver vazio;
     - houver **sessão interativa ativa E tarefa pesada** (Blender, Godot, ou Python com CPU a subir);
     - a lista de SHA mudar entre a liberação e o pré-voo;
     - **(E2)** o `NODE_V8_COVERAGE` ou o `NODE_COMPILE_CACHE` não estiverem vazios;
     - **(E3)** o `quser` ou o `Get-Process` derem um erro que não seja "sem sessão" nem "sem processo": o estado é desconhecido e não se corre.

9. **Saídas:** nenhum arquivo. Só o relatório da consola (TAP/spec).

10. **Desfazer:** não há nada a desfazer, porque nada é escrito. Em caso de pendura, o timeout da ferramenta mata o processo.

    **NÃO TOCAR:** tudo fora de `rascunhos\servidor\` (só leitura dela).

11. **Privacidade:** só dados fictícios. Os canários são valores-isca e não são de ninguém.

12. **Retorno:** o Claude lê o relatório e decide as correções. As correções mudam o código, e cada correção leva a um novo pacote (P-PC-02b…).

13. **Regra do hash (E5).** O SHA-PV é o SHA-256 da lista do pré-voo (o texto unido por `\n`), calculado como na E4 e escrito aqui depois das duas liberações. A partir daí, nenhum arquivo de `rascunhos\servidor\` muda; se mudar, é preciso uma nova liberação (P-PC-02b). A lista completa e o SHA-PV são colados no item 14 antes da execução.

    **Liberações:**
    - Crítico Infra/Convivência ☐
    - Crítico Código ☐
    - SHA-PV: ________

14. **Registo de execução**

**Liberações:**

- Infra: LIBERA COM EMENDAS (E1–E5, aplicadas);
- Código: LIBERA (sem correções obrigatórias; as guardas em `novoId` e `d6` ficam para o P-PC-02b).

**SHA-PV = `EE394EDA642B6F5E720256325BB8C5DCCC587908AC5D5A34B0D5192BFE37945F`.** É o SHA-256 da lista de 20 arquivos de `rascunhos\servidor\`, medido no pré-voo de 06/11. O texto fica congelado.

**Tentativa 1 (06/11), pré-voo: NÃO CORRE.**

- `PCdaNasa` ✔
- Node v26.13.0 ✔
- `NODE_OPTIONS` vazio ✔
- `NODE_V8_COVERAGE` e `NODE_COMPILE_CACHE` vazios ✔
- **C: livre = 12.992.913.408 B (≈12,99 GB), abaixo do piso de 15 GB ✘.** Na primeira leitura do dia eram ≈24,3 GB.
- **Sessão `console` ativa, com ocioso "nenhum", E tarefa pesada:** Godot (PID 31800, CPU de 1159 s, a subir; não é do Muse) e python (PID 15032, CPU de 205 s, a subir; a CP-05 do Muse) ✘.

O passo 7 não foi executado e nada foi criado.
