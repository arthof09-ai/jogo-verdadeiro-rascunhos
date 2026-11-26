# Provas da ORDEM-PLANO-2-F1-FECHO (F4 + F5 + F6)

O ESTADO-FINAL é `ESTADO-FINAL-ORDEM-PLANO-2-F1-FECHO.md`, na raiz. As provas do F4 e do F5 estão dentro do pacote da F1
(`provas/ordem-plano-2-f1/`: o `README.md`, o `suites/resumo.txt`, o `suites.sh` e a pasta `dados/recontar/`). Aqui ficam
os logs do F6 e das suites do fecho.

| Ficheiro | O quê |
|---|---|
| `suites/camera_segue.log` | 22 de 22, com o caso 11 (o PANORAMA) |
| `suites/camera_segue-SEM-FOCO-NO-EVENTO.log` | mutação, 19 de 22 (as linhas `# diff:` mostram a mutação) |
| `suites/camera_segue-PANORAMA-NAO-FOCA.log` | mutação nova, 20 de 22: só o caso 11 a apanha |
| `suites/canario_privacidade.log` | 10 de 10 |
| `suites/sonda-caminhos-copia-limpa.log` | 0 caminhos do PC novos (cópia por `git archive`) |
| `suites/actualizar-listas.log` | listas da retoma: 0 novos, 0 tirados |
