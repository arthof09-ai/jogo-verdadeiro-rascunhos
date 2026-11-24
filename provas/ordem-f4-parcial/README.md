# Provas — ORDEM-F4-PARCIAL (dados físicos validados + vetores-ouro)

Tudo isto foi corrido no PC, com Node `v26.13.0` (ver `logs/node-versao.txt`), na ponta `bcf02d1` da linha
`fable/integracao-50`. As provas do CI são as dos runs `45353754892` (Testes dos rascunhos) e `45353754800` (Sonda de
privacidade), ambos `success` na mesma ponta.

Os caminhos absolutos do PC foram redigidos nos logs (`<TEMP>` e `<pasta-da-ordem>`). Nada mais mudou nos logs.

## Os logs

| Ficheiro | O que prova |
|---|---|
| `logs/dados-fisicos.log` | `testes/dados-fisicos.test.mjs`: 7/7. Inclui o valor físico **dentro** do intervalo, que passa e manda o cartão ao Mestre, e o valor **fora**, que é recusado sem cartão nem vez gasta e fica gravado como RECUSADA |
| `logs/servidor-com-allow-net.log` | A suite do servidor inteira, com `--allow-net` (Node 26): 442 testes, 432 passam, **0 falham**, 10 saltados |
| `logs/servidor-comando-do-ci.log` | A mesma suite, com o comando exacto do CI e sem `--allow-net`: 442 testes, 425 passam, 7 falham, 10 saltados. As 7 falhas são os testes de rede V20 e da ordem 30 (`ERR_ACCESS_DENIED` do modelo de permissões do Node 26 neste PC). São ambiente, não regra |
| `logs/servidor-base-1e2baab-comando-do-ci.log` | O controlo: a ponta de antes (`1e2baab`), com o mesmo comando, falha **os mesmos 7** (435 testes, 418 passam). A ordem não as introduziu. No CI (Node do runner) a suite passa toda |
| `logs/motor-real-corrida-1.log`, `logs/motor-real-corrida-2.log` | O job `motor-real` reproduzido no PC: o motor oficial embrulhado como no CI (`MOTOR_MJS`), duas corridas, 0 falhas. Os vetores-ouro dão `517/517` (100 %) nas duas |
| `logs/gerar-corrida-1.log`, `logs/gerar-corrida-2.log` | A geração dos vetores em dois processos separados (pastas `vo-1` e `vo-2`). O SHA de cada grupo é igual nas duas e igual ao dos ficheiros gravados. As linhas só diferem no nome da pasta |
| `logs/sha256-corrida-1.txt`, `logs/sha256-corrida-2.txt` | O `sha256sum` dos 10 ficheiros gerados (9 grupos + `MANIFESTO.json`) em cada corrida. Os dois ficheiros são **iguais** (`diff` vazio): duas corridas byte-idênticas |
| `logs/sha256-motores-usados.txt` | O SHA-256 do motor oficial usado (`a91c021c…`) e o da cópia mutada do controlo (`41ffaba3…`) |
| `logs/controlo-motor-mutado.log` | O controlo negativo: uma cópia do motor com **um só** peso das desgraças mudado (35→34). O teste falha em 3 de 4 asserções: o SHA, os casos (457/517, só o grupo 03 cai para 6/66) e os bytes. Prova que os vetores medem o motor e não passam por acaso |
| `logs/grep-regra-cliente.log` | O grep da regra no cliente: **0 achados** nas duas buscas (a da JV1.1 e a da validação do intervalo nos `.gd`). O cliente Godot não calcula regra |

## Como repetir

```sh
# dados físicos (não precisa do motor)
cd rascunhos/servidor && node --test testes/dados-fisicos.test.mjs

# vetores-ouro (precisa do motor oficial, que não se copia para o repositório), na pasta rascunhos/servidor/
node motores/embrulhar.mjs <vlab-completo.js> <motores.mjs>     # embrulha como o job motor-real
MOTOR_MJS=<motores.mjs> node --test testes-motor-real/vetores-ouro.test.mjs

# gerar outra vez numa pasta à parte e comparar com os gravados
node testes-motor-real/gerar-vetores.mjs <motores.mjs> <pasta>
sha256sum <pasta>/*.json
```
