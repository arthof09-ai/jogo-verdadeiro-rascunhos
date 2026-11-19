# Provas — Ordem NADO (19/11/2026)

Godot 4.7.2 oficial; render por software (Mesa llvmpipe, Xvfb), sem GPU. Ver `ESTADO-FINAL-ORDEM-NADO.md` na raiz.

- `clipe/` — o `nadar_v1` (testes/manequim/nado-v1.glb) no manequim, de lado, de frente e de cima, em 4 tempos do ciclo,
  e um zoom a t = 1,13 s. Bancada de ensaio da sessão (não versionada): chão neutro, luz simples.
- `quadros/` — a bancada `testes/video_lago.gd --modo=funda` (1280×720, 30 qps fixos): antes, a água sobe, a nadar
  (nado-1, nado-3, nado-4, com a esteira) e a sair (de volta ao `andar_v3`).
- `funda_fases.json`, `funda_medicao.json` — as fases do guião e a medição dessa corrida (`nado.quadros_a_nadar` = 601).
- `rasa-antes-depois/` — `--modo=rasa` com a árvore de antes (`c94df09`) e com a de agora: a série da medição é igual
  linha a linha (742/742), as fases e a duração também.
- `suites/` — logs: conversor (`converter_nado.log`), abrir_scripts (104/0), rodar_testes (226/226), arranque
  («pronto») e a corrida da funda.
