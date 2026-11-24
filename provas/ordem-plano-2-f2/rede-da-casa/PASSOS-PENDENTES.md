# JV3.4b — a prova na rede da casa: PROVA PENDENTE (não é falha)

A ordem manda: o lado Android é o telemóvel do Mestre, **só com a palavra dele na hora** (é ele quem abre o link). Esta
corrida foi feita sem o Mestre presente (corrida não interactiva no PC), por isso a JV3.4b **não correu**. Fica aqui
o guião exacto, para quem estiver com ele. O resto da F2 (exports, mesa na mesma origem, QR, 3 bots/25 s, V1.0 no PC)
está entregue e provado sem ele.

Também fica pendente, pela mesma razão, **o JSON da V1.0 do telemóvel do Mestre** (o passo 6). A V1.0 do PC está nas
provas (`web/`).

## O que é preciso

- O PC (o servidor) e o telemóvel do Mestre (Android) **na mesma rede Wi-Fi de casa**. O PC pode estar no cabo.
- No PC: o repositório na ponta desta ordem e o export web em `build/web/`. Baixe o artefacto `export-web` do último
  CI verde do workflow «Aparelhos (F2)», ou exporte com o Godot 4.7.2:
  `Godot --headless --path rascunhos/cliente --export-release Web`.
- Um cronómetro (o do telemóvel de outra pessoa, ou o relógio do PC).
- Só as fichas fictícias de bancada: «Espadachim de Bancada» e «Arqueira de Bancada».

## Os passos (cerca de 15 minutos)

1. **Arrancar a mesa no PC** (uma janela de terminal; o registo fica no ficheiro):

   ```
   cd rascunhos/servidor
   node aparelhos/mesa-prova.mjs --porta=8080 --estatica=../../build/web --medicoes=../../../medicoes-casa --jogadoras=2 --mestre-auto --criaturas | tee ../../../mesa-casa.log
   ```

   O terminal mostra o **QR** e os links (`http://192.168.x.y:8080/`). Se a firewall do Windows perguntar, permita o
   Node na **rede privada**.
2. **O QR grande:** no PC, abra `http://localhost:8080/qr` no navegador.
3. **Telemóvel do Mestre (Android), com a palavra dele:** ele lê o QR com a câmara e abre o link. **Não instala
   nada.** Entra com o nome `Arqueira de Bancada` e a senha `prova-arqueira`.
   → Foto 1: o telemóvel na arena.
4. **PC (a 2.ª jogadora):** noutra janela do navegador, abra o mesmo link e entre com `Espadachim de Bancada` /
   `prova-espadachim`.
   → Foto 2: os dois ecrãs lado a lado, a mesma partida.
5. **10 turnos:** joguem 10 vezes (5 de cada jogadora: «Mover» uma casa e «Encerrar», ou só «Encerrar»). As
   criaturas jogam sozinhas.
   - **No 5.º turno**, quando for a vez da jogadora do PC: **desligue o Wi-Fi do telemóvel** e ponha o cronómetro a
     andar. A jogadora do PC joga a vez dela enquanto isso.
   - **Aos 25 s, ligue o Wi-Fi outra vez.** Pare o cronómetro quando o telemóvel voltar a mostrar a mesa (o aviso
     de ligação some). **Aceite: ≤ 30 s**, e a jogada feita no PC durante o corte aparece no telemóvel (nada se perde).
   → Foto 3: o telemóvel depois de voltar, com a jogada do PC à vista.
   - O `mesa-casa.log` regista a hora de cada `SAIU` e `ENTROU` (com `token` e o `lastSeq`): é a medida objectiva da
     reconexão.
6. **A V1.0 no telemóvel do Mestre:** abra `http://192.168.x.y:8080/?medir=1` (o QR pequeno de «Medir este
   aparelho», na página `/qr`). **Abra e espere 1 minuto, sem tocar.** O JSON aparece no ecrã e vai sozinho para
   `medicoes-casa/`. **Repita uma vez** (a 2.ª tem de dar o mesmo com ±10 %).
   → Foto 4: o ecrã com o JSON.
7. Feche a mesa com Ctrl+C. Junte a esta pasta: as fotos, o `mesa-casa.log` e os dois JSON de `medicoes-casa/`.

## Como se confere

- O `mesa-casa.log` tem: as 2 entradas por senha; um `SAIU Arqueira de Bancada` no corte; um
  `ENTROU Arqueira de Bancada (token, lastSeq N …)` depois. A diferença de hora entre «Wi-Fi ligado» (cronómetro) e
  esse `ENTROU` tem de ser ≤ 30 s. Com `token` e `lastSeq`, ela voltou ao mesmo lugar e recebeu só o que faltava.
- Os dois JSON da V1.0 trazem `fps_mediana`, `fps_p5`, `chamadas_mediana`, `chamadas_max`, `gpu`, `viewport`, `dpr`;
  a 2.ª corrida fica a ±10 % da 1.ª nos três números.
- As fotos não mostram nada além das fichas fictícias.

## Porque é que já há confiança (sem a prova da casa)

- O `rede-3-bots` (CI e PC): 25 s sem rede, a reentrada com o token e o `lastSeq`, os eventos que faltavam sem
  snapshot, o hash lógico igual ao da corrida sem corte. Na corrida do PC de 24/11 a reentrada demorou **6,45 s** (A)
  e **3,21 s** (B) depois de a rede voltar (`../rede-3-bots/prova-3-bots-pc.log`).
- O cliente Godot volta a tentar com a espera 1-2-4-8 s (tecto 8 s, era 30 s). Na web, o evento `online` do
  navegador faz tentar logo. O pior caso depois de a rede voltar fica abaixo de 10 s.
- O export web recebe o `ROOM_SNAPSHOT` no Chromium (PC e CI). O `.exe` do Windows recebe-o no PC (`../windows/`) e no
  runner Windows do CI. O APK x86_64 recebe-o no emulador do CI (job `android`). No PC não há emulador nem telemóvel
  no `adb`, por isso o APK não correu aqui.
- **A guarda do Android no telemóvel:** o link do QR é `http://192.168.x.y:8080/`, e o Chrome do Android abre-o como
  qualquer página. A guarda `ws://` só-rede-local vale para o APK, não para o navegador. O telemóvel do Mestre entra
  pela web e não instala nada.
