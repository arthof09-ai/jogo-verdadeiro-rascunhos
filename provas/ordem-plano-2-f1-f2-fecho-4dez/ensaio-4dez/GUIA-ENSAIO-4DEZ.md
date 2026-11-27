# Guia do ensaio da casa — sexta-feira 4/12/2026 (JV3.4b)

**Para o Mestre.** Um passo de cada vez. Demora uns **15 minutos**. Precisa de:

- o **PC da mesa** (o que tem o repositório e o Node; pode estar no cabo);
- o **seu celular Android**, na **mesma rede Wi-Fi** do PC;
- um **cronómetro** (o relógio do PC serve);
- alguém para tirar **4 fotos** (ou o próprio Mestre, com outro aparelho).

Só se usam personagens **fictícias** de bancada (a «Arqueira de Bancada» contra o «Lobo» e o «Bruto»). Nada das fichas reais.

> **De onde vem o jogo:** a via principal é o build do **CI verde** (artefacto `export-web` do run `45946124164`, na
> ponta `c64719d`). Está copiado em `G:\Meu Drive\RPG Assimilação\13 — Trabalho das cadeiras\f1-f2-fecho-4dez\build-web\`
> (com o `SHA256SUMS.txt`). A alternativa, se essa pasta faltar: exportar a web no PC com o Godot 4.7.2
> (`Godot --headless --path rascunhos/cliente --export-release Web`, que escreve em `build/web/`).
> *(Correcção E-2 da sentença 595, já aplicada aqui.)*

---

## Passo 1 — Abrir a mesa no PC (2 min)

1. No PC, abra a pasta do repositório e dê **duplo clique** em
   `provas\ordem-plano-2-f1-f2-fecho-4dez\ensaio-4dez\arrancar-ensaio.cmd`.
2. Se o Windows perguntar pela **firewall**, escolha **permitir o Node na rede privada**.
3. Espere a janela mostrar o **QR** e estas linhas (o número do IP pode ser outro):
   ```
   http://192.168.1.38:8080/
   QR grande no PC:  http://localhost:8080/qr
   Mestre (no PC):   http://localhost:8080/   PIN 90210777
   Celular:          nome «Arqueira de Bancada»  senha «bancada-arqueira»
   ```
   **Não feche esta janela** até ao fim do ensaio.

## Passo 2 — O Mestre entra no PC (1 min)

1. No navegador do PC, abra `http://localhost:8080/`.
2. Carregue em **«Sou o Mestre»**, escreva o PIN **90210777** e carregue em **«Entrar como Mestre»**.
3. Se aparecer a mesa **em pausa**, carregue em **«Continuar»**.
4. Noutro separador, abra `http://localhost:8080/qr` — é o **QR grande**, para o celular ler.

## Passo 3 — O celular entra, sem instalar nada (1 min)

1. No celular, abra a **câmara** e aponte ao QR grande do PC. Toque no link que aparece (abre no Chrome).
   (Sem QR: escreva no Chrome o link `http://192.168.x.y:8080/` que a janela do Passo 1 mostrou.)
2. **Não instale nada.** O jogo abre no navegador e mostra o lobby.
3. No lobby escreva o nome **`Arqueira de Bancada`** e a senha **`bancada-arqueira`** e carregue em **«Entrar»**.
4. Ela aparece na arena, ao lado do Lobo e do Bruto.

→ **FOTO 1:** o celular na arena.
→ **FOTO 2:** o celular e o ecrã do PC **lado a lado**, a mesma partida.

## Passo 4 — Jogar 10 turnos (5 min)

- Quando for a **vez da Arqueira** (o celular diz «na vez»), jogue no celular: **«Mover»**, **«Atacar …»** (o alvo) e **«Encerrar a vez»**.
- O Lobo e o Bruto **jogam sozinhos**. O Mestre só olha (no PC **não carregue em «Terminar batalha»**).
- Conte os turnos: cada vez que a vez passa (da Arqueira, do Lobo ou do Bruto) é **1 turno**. Joguem **pelo menos 10**.

## Passo 5 — Desligar o Wi-Fi 25 segundos (1 min)

Faça isto **com a Arqueira ainda de pé**, logo a seguir a ela carregar em **«Encerrar a vez»** (assim os monstros jogam
enquanto o celular está sem rede — é isso que não se pode perder):

1. **Desligue o Wi-Fi do celular** e ponha o **cronómetro a andar**. Anote a hora do PC: ______
2. Aos **25 segundos**, **ligue o Wi-Fi outra vez**. Anote a hora do PC: ______
3. Pare o cronómetro quando o celular **voltar a mostrar a mesa** (o aviso de ligação desaparece).
   **Tem de ser ≤ 30 s** depois de ligar o Wi-Fi.
4. Confira: o que os monstros fizeram durante o corte aparece no celular (a **vida da Arqueira** no celular é a
   mesma do ecrã do PC). **Nada se perdeu.**

→ **FOTO 3:** o celular depois de voltar, com a mesa à vista.

## Passo 6 — Até ao fim da batalha (3 min)

- Continuem a jogar até a **Arqueira cair e morrer** (os testes de morte são automáticos).
- A batalha tem de acabar **por morte** — **não** carregue em «Terminar batalha» no PC.

## Passo 7 — A medição V1.0 do celular (1 min)

1. No celular, abra `http://192.168.x.y:8080/?medir=1` (o **QR pequeno «Medir este aparelho»** na página `/qr` do PC).
2. **Espere 1 minuto sem tocar.** Aparece um texto (JSON) no ecrã; vai sozinho para o PC.

→ **FOTO 4:** o ecrã do celular com o JSON.

## Passo 8 — Fechar e guardar (1 min)

1. Na janela do Passo 1, carregue **Enter**. A mesa fecha e diz onde guardou o resultado
   (`…\ensaio-4dez-privado\resultado-<data>\`).
2. Copie **essa pasta** e as **4 fotos** para
   `G:\Meu Drive\RPG Assimilação\13 — Trabalho das cadeiras\f1-f2-fecho-4dez\resultado-ensaio\`.
3. Escreva no `REGISTO-ENSAIO-4DEZ.md` as horas do Passo 5 e o tempo do cronómetro.

Quem lavra o resultado depois corre, no repositório:
`node provas\ordem-plano-2-f1-f2-fecho-4dez\ensaio-4dez\conferir-ensaio.mjs <pasta resultado-…>`
e preenche o registo com o que ele disser.

---

### Se alguma coisa correr mal

| O que acontece | O que fazer |
|---|---|
| A janela do Passo 1 diz «FALHA: o motor não é o VLAB real» | Ligue a internet do PC e dê duplo clique outra vez (só a 1.ª vez precisa de rede) |
| O celular não abre o link | Celular e PC na mesma rede Wi-Fi? A firewall deixou o Node na rede privada? |
| A mesa fica «em pausa» | O Mestre carrega «Continuar» no PC |
| O celular pede outra vez o nome e a senha | Escreva-os outra vez; anote no registo que aconteceu |
| Carregou-se em «Terminar batalha» por engano | Anote no registo; feche (Passo 8) e repita do Passo 1 |
