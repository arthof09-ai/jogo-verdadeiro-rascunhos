# Ordem GRAMA: a relva da floresta guarda a passagem (item 2 da fila visual). ESTADO FINAL

*Fecho da ordem, 2026-11-16, em regime de SUCESSÃO (Plano C): a sessão original (Claude conta 1, no PC)
commitou o grosso em `37a6db9` e morreu no limite de sessão sem render as provas; a primeira sessão do
Plano C (Muse Spark, na VM do coordenador, sem GPU — render por software, llvmpipe) reviu o trabalho,
corrigiu o que faltava e rendeu os filmes da baixa e da média; a segunda sessão do Plano C (também Muse
Spark, mesma VM) rendeu a alta e o combinado, montou o pacote, re-correu os testes e fundiu o ramo —
cada queda da máquina (~2 h) foi retomada do ponto exacto, sem repetir modo fechado. Godot 4.7.2.
Ramo `fable/grama-46` (base: a linha de integração à Ordem 57, `9b97066`), fundido sobre a ponta de
`fable/integracao-50` (`75cc947`, confirmada no fetch imediatamente antes da fusão). Não se tocou na
main, no ramo vivo, na PR #21 nem nos workflows.*

## Resumo

**Quem atravessa a relva da arena deixa um rastro**: a erva abre/dobra por onde a figura passou e recupera
sozinha — cada altura à sua maneira. Três alturas sobre o campo (baixa 0,30 m, média 0,95 m, alta 1,40 m),
três jeitos distintos (a baixa abre pouco e salta de volta em 0,9 s com um ressalto de mola; a média abre já
à frente de quem vem e fecha logo atrás, 1,55 s; a alta deita-se para os lados num corredor que se segura
3 s e fecha devagar, 12 s). Fora do caminho, a erva continua ao vento do mundo (Ordem 43): o rastro soma-se
ao vento, contido na erva deitada. Nada é permanente e nenhuma regra lê isto — é só apresentação.

## O que mudou

| commit | o quê |
| --- | --- |
| `37a6db9` | (sessão original) O sistema: `mapa/floresta/rastro_relva.gd` (o mapa do rastro e as contas das três alturas), `shaders/rastro_relva.gdshaderinc` (as mesmas contas do lado do desenho), as manchas de altura em `campo_floresta.gd` e em `shaders/relva.gdshader`, o rastro também nas hastes, a altura da malha de cada tufo a viajar na instância (`relva_floresta.gd`), a peça de prova (`testes/manequim/andar-v3.glb`, SHA-256 8413b039…) e a bancada `testes/video_grama.gd`. |
| `b3c13dc` | (Plano C, 1.ª sessão) O pacote do terreno do servidor refeito com `exportar_terreno.gd`: o `37a6db9` mexera em `campo_floresta.gd` sem o refazer e `rodar_testes` falhava 176/177. Só o cabeçalho muda (o SHA da fonte); os dados do terreno são os mesmos. 177/177. |
| `7e73a31` | (Plano C, 1.ª sessão) A bancada aceita `--res=LARGxALT` para o filme (sem `--res`, tudo igual). Nesta VM sem GPU o 1280×720 não cabia nas janelas entre reinícios da máquina; a alta e o combinado renderam com a cena a 854×480. |
| `52618a1` | (Plano C, 2.ª sessão) `provas/ordem-grama/`: os 4 vídeos, as medições, as capturas e o README. |
| `9437027` | (Plano C, 2.ª sessão) Fusão de `fable/grama-46` em `fable/integracao-50`; o único conflito (o pacote do terreno, que os dois lados refizeram) resolveu-se refazendo o pacote com `exportar_terreno.gd` sobre a árvore fundida (658.536 B, 9 redes) — nunca à mão. |
| `079f71f` | (Plano C, 2.ª sessão) Listas da retoma e MANIFESTO refeitos pós-fusão (depois.txt: 363 entradas; MANIFESTO: 412 ficheiros). |
| (este) | O ESTADO FINAL. |

## As provas (`provas/ordem-grama/`)

- **Vídeos** (.mp4 H.264 convertidos dos .avi do Movie Maker do Godot, sem cortes nem mudança de
  velocidade; o Movie Maker escreve contentores 1920×1080 — os .mp4 vão ao tamanho a que a cena foi
  rendida em cada corrida):
  - `videos/grama-baixa-recta-e-curva.mp4` — 1280×720, 35,2 s (14.662.239 B): a baixa em recta e em curva;
  - `videos/grama-media-recta-e-curva.mp4` — 1280×720, 35,8 s (15.006.082 B): a média em recta e em curva;
  - `videos/grama-alta-recta-e-curva.mp4` — 854×480, 46,3 s (8.751.629 B): a alta em recta e em curva, com o corredor a fechar;
  - `videos/grama-tres-alturas-lado-a-lado.mp4` — 854×480, 58,2 s (8.206.845 B): as três lado a lado, atravessadas em
    sequência (recta para leste, curva para oeste) e a recuperação de cada uma. **Nota:** a simulação correu
    67,1 s, mas o Movie Maker perdeu os quadros finais dentro do .avi (1.744 de 2.016 descodificáveis) —
    o filme chega ao fim da curva e aos primeiros ~4 s da paragem; a recuperação completa lê-se nos filmes
    individuais, na captura `tres_t66s_recuperada.jpg` e nas medições (declarado também no README das provas).
- **Medição** (`medicao/`): por modo, os pés no relevo quadro a quadro, a abertura nas sondas ao longo do
  tempo e os tempos de recuperação medidos contra os da tabela. O `medicao_perfis.json` (FPS e chamadas de
  desenho por perfil, com e sem as três alturas e o rastro — **nesta VM, por software**) está **a caminho**:
  à data deste fecho vai 1 de 6 casos medido (Alto, sem as três alturas: 4.524 ms/quadro, 93,0 chamadas de
  desenho, 1.200.487 primitivas, 32.941 tufos) — cada caso leva ~35–55 min nesta VM e as janelas entre
  reinícios são de ~2 h; a medição continua e o ficheiro entra em commit seguinte declarado.
- **Capturas** de apoio etiquetadas (não substituem os vídeos).

**Os números que provam o rastro** (sondas da bancada, a mesma conta do shader):
- baixa: abre 1,0 debaixo de quem passa; recuperação medida 0,900 s = tabela 0,9 s;
- média: abre 1,0 (e já à frente, pelo ovo da pegada); fecha 1,13 s depois do patamar (tabela: 0,25 + 1,3 s);
  a sonda LONGE do caminho fica a 0,0 — fora da passagem só há vento;
- alta: abre 1,0; a sonda fecha aos 19,167 s do filme — recuperação medida de 7,534 s desde o último
  máximo (a tabela conta 12 s desde o carimbo da passagem: 3 s toda aberta + 9 s a fechar);
- combinado (as três sondas no mesmo filme): 0,800 s · 1,133 s · 7,533 s — os mesmos valores dos filmes
  individuais; o instrumento é consistente entre corridas;
- no fim de cada vídeo: 0 pontos abertos — nada fica marcado no campo;
- pés no relevo: folga entre −0,008 e +0,041 m (média 0,019 m) — a figura nem flutua nem afunda;
- chamadas de desenho da cena nos vídeos: 83 (baixa) · 84 (média) · 85 (alta) · 96 (combinado).

**Testes e CI:** `rodar_testes.gd` re-corrido no fim: **177 de 177 verificações passaram**. CI da ponta
da linha (`079f71f`): **9 de 9 jobs verdes** nos «Testes dos rascunhos» + «Sonda de privacidade» verde —
incluindo o `retoma-pc`, que vinha vermelho desde 15/11 (a receita comparava contra um manifesto
desactualizado face aos shaders da relva; a fusão + as listas refeitas puseram-no verde).

## A técnica (resumo; a folha completa está em `rastro_relva.gd`)

Um mapa do chão (256×256 pontos sobre a zona jogável + 4 m de margem) guarda por ponto a hora da última
passagem, o rumo para onde a erva fugiu e a força (0–1). A CPU só escreve à volta de quem anda — uma pegada
em forma de ovo, 2,4 raios para a frente e 0,8 para trás, refrescada a cada 0,05 m de caminho (e no sítio,
de 0,12 em 0,12 s, para a erva não fechar debaixo de quem está parado). O shader lê o ponto debaixo da raiz
de cada tufo e dobra-o conforme a altura do próprio tufo (as fronteiras e as respostas são as mesmas contas
nos dois lados, de uma tabela só: `rastro_relva.CLASSES`). Passado o tempo de recuperação da erva mais
lenta, o mapa volta a zero e o shader nem o lê: sem ninguém a andar, o custo do rastro é nenhum.

## Onde parou / Próximo passo / O que falta conferir

- **Onde parou:** tudo na linha `fable/integracao-50`, ponta `079f71f` (+ este ficheiro): sistema,
  pacote de provas, testes 177/177 e CI 9/9 verde. Só falta o `medicao_perfis.json` completo (1 de 6
  casos à data do fecho), que entra em commit seguinte declarado quando a medição acabar.
- **Próximo passo:** o juízo é da bancada e do olho do Mestre sobre os vídeos. A fila visual segue para a
  ÁGUA (o lago) e a NEVE, nas suas ordens próprias — nada disso foi tocado aqui. Com a GRAMA fundida, a
  ÁGUA (ramo `fable/agua-66`) já pode fazer a sua própria fusão, como a sua ordem manda.
- **O que falta conferir:** (1) os FPS foram medidos nesta VM por software — no PC com a RTX os números
  serão outros (a corrida `medir` da bancada corre lá sem mudanças); (2) o rastro segue nós registados por
  `rastro.seguir(nó, raio)` — ligar as figuras do jogo a esse registo é da ordem das figuras 3D, não desta;
  (3) a erva baixa reage de forma subtil à câmera das provas (13,5 m) — lê-se no movimento do vídeo e nas
  sondas; se o Mestre a quiser mais legível, é afinar `lim0/angulo` da classe baixa na tabela, num só sítio;
  (4) o filme combinado perdeu os últimos ~9 s de quadros dentro do .avi (ver a nota nas provas) — se o
  coordenador o quiser inteiro, é re-renderizar só o combinado (~85 min numa janela limpa desta VM).
