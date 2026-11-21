# ESTADO FINAL — ORDEM-CAIXA-MANEQUIM (Claude conta 2, PC · 21/11/2026)

**Ramo:** `claude2/caixa-manequim` a partir de `fable/integracao-50` @ `e38b4fc` (a CAIXA-JANELA já fundida: as
capturas têm o comportamento corrigido da caixa). **1 commit**, publicado. **Não fundido**, porque a fusão é do coordenador.
**Código do jogo: nada mudou.** O commit só traz a prova (`provas/ordem-caixa-manequim/`) e este estado.

## As 5 capturas: onde estão
`provas/ordem-caixa-manequim/cliente/`, com os mesmos nomes das antigas para se compararem lado a lado:

| # | momento | nova (manequim) | antiga (cápsula) |
|---|---|---|---|
| 1 | dinâmica: a Espadachim entra, ela na vez | `1-entrou-dinamica.png` | `provas/ordem-caixa-hud-jogadora/cliente/1-entrou-dinamica.png` |
| 2 | iniciativa: Bruto na vez | `2-iniciativa.png` | `…/2-iniciativa.png` |
| 3 | desligada: a caixa ausente | `3-desligada.png` | `…/3-desligada.png` |
| 4 | religada e avançada: Arqueira na vez | `4-religada-avancou.png` | `…/4-religada-avancou.png` |
| 5 | reentrada: a caixa reconstruída | `5-reentrou.png` | `…/5-reentrou.png` |

**Sobre o caminho da ordem:** a ordem aponta para `provas/ordem-caixa/cliente/`, mas essas 5 capturas são da
CAIXA-PERSISTENTE (o **ecrã do Mestre**, a sair e a voltar a entrar). Os 5 momentos que a ordem descreve (dinâmica,
iniciativa, desligada, religada e avançada, reentrada) são os da prova viva da **CAIXA-HUD-JOGADORA**, e a ordem diz
que é essa a prova a refazer. Por isso usei essa prova e o enquadramento dela.

Prova viva com o jogo a correr: cliente real (arena + HUD pela Rede), servidor de mesa real com o motor VLAB real,
Godot 4.7.2, RTX 4060, janela 1028×720, a mesma da prova antiga. **46/46** verificações: as 36 da prova antiga, mais
o manequim aberto e conferido, e 2 por momento (todas as figuras com manequim e 0 cápsulas à vista; cada retrato da
caixa copiado do manequim). Vi as 5 capturas uma a uma.

## O que mudou face às de cápsula
1. **As figuras em cena** são o manequim de referência: Mannequin_F (UAL2) com o ANDAR v3,
   `testes/manequim/andar-v3.glb`, sha256 `8413b039…` conferido, no quadro 0 (a pose das capturas do LAGO-MAIOR).
   Não aparece nenhuma cápsula. As bases de contacto e os nomes por cima ficam como o jogo os põe.
2. **Os retratos da caixa** são o manequim. O jogo copia o modelo em cena (`hud/retratos.gd`), por isso o retrato
   segue a figura, como antes.
3. **As cores da caixa** (painel sangue, moldura ouro, fundo do retrato raro) são diferentes das capturas antigas.
   Não fui eu que as mudei: as antigas são de 20/11, antes da PALETA-C ponto 2 (`a63c2c1`, 21/11), e estas já mostram
   a tabela. Não pus nenhuma cor nova. O manequim usa os materiais que traz.
4. Tudo o resto é igual: os mesmos momentos, a mesma semente, o mesmo cenário, as mesmas ordens e as mesmas vezes
   (o relato bate linha a linha com o antigo).

## Privacidade
Nos 5 momentos: nenhuma mensagem do Mestre chega ao aparelho dela, a caixa só leva `ligada/ordemPor/ordemDinamica`,
e nenhum nome verdadeiro, vida, alma ou PA aparece nos textos da caixa. Não há números na vista da jogadora.

## Pontos para o coordenador / o Mestre (não mexi)
1. **Com o manequim, o retrato mostra o corpo inteiro e não o busto.** `retratos.gd` só recorta o busto quando a
   figura é mais de 1,2× mais alta do que larga. A malha esfolada do manequim mede-se na pose de bind, em T
   (1,76 m de largo × 1,81 m de alto, pelos limites do GLB), por isso cai no caso «corpo inteiro». Se o Mestre quiser
   o busto, o retrato tem de se medir na pose e não na malha em T. Fica para uma ordem própria: esta era só capturar.
2. Com o manequim em cena, os nomes por cima das figuras continuam miúdos à distância da câmara de jogo (já eram assim
   com as cápsulas).
3. O manequim entra só pela ferramenta de prova: o jogo continua a desenhar cápsulas. Num clone novo é preciso
   `godot --headless --path rascunhos/cliente --import` antes de correr a prova, porque sem a cache as `class_name` não
   resolvem.

Correr de novo: `bash provas/ordem-caixa-manequim/ferramentas/correr-prova-caixa-manequim.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`.
