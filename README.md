# jogo-verdadeiro — rascunhos (repositório PRIVADO provisório)

**Estado:** provisório e **privado**. Criado por CM-000009 (Muse) em 2026-11-06, ao abrigo da IBX-253 (regra do Mestre: *«tudo o que avançar no jogo e no app fica registado no Drive e no GitHub — nada pode ficar preso a só você»*), ponto 2 — a via do repositório privado provisório enquanto a JV0.5 não decide o repositório definitivo. **A decisão definitiva do repositório fica na JV0.5.**

## O que vive aqui

Os rascunhos de código do jogo-verdadeiro escritos por CM-000008 (Claude) no PC do cunhado (`C:\Users\txcga\RPG_Local\jogo-verdadeiro\`):

- `rascunhos/cliente/` — cliente Godot (arena, HUD, câmara, rede, shaders Arcane, testes).
- `rascunhos/servidor/` — núcleo do servidor de mesa em Node (só dados fictícios/de exemplo).
- `rascunhos/validador-glb/` — validador GLB em Node + lista de ossos UAL1.
- `pacotes/` — pacotes P-PC-01 e P-PC-02 (registos de execução no PC).
- `MANIFESTO-SHA256.txt` — manifesto SHA-256 de cada ficheiro (a ponte acrescenta linhas a cada versão nova).

## Espelhos e rotina

- **Drive:** os mesmos ficheiros vivem em «RPG Assimilação» → `12 — Código/jogo-verdadeiro/` (ponte IBX-249, repetida a cada pacote corrido ou versão nova dos rascunhos).
- **Rotina (IBX-253, ponto 4):** a cada pacote corrido ou versão nova dos rascunhos, a ponte PC → Drive repete-se, o manifesto ganha linhas, e este repositório recebe a mesma actualização.

## Regras deste repositório

- **Nunca público.** Só código e dados fictícios — nenhum dado do Mestre nem da Party.
- Excluídos por regra: `pacotes/P-PC-01/saida/` (traz cópia do motor) e artefactos de importação do Godot (`.godot/`, `*.import`) — ver `.gitignore`.
- A sonda de privacidade (`.github/workflows/privacidade.yml`) corre a cada push.
