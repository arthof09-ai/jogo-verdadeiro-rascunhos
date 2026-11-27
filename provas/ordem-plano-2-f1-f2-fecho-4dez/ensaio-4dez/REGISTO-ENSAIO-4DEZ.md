# Registo do ensaio da casa — 4/12/2026 (JV3.4b)

**Estado: PREPARADO, POR CORRER.** Este modelo preenche-se quando o Mestre correr o ensaio
(guia: `GUIA-ENSAIO-4DEZ.md`). Até lá nenhuma linha abaixo está provada.

## O que já estava pronto antes do ensaio (27/11, a cadeira)

- Build web: artefacto `export-web` do run verde `45946124164` (ponta `c64719d`); `index.pck` SHA-256
  `fa4ee2b3430393d8e5d1bcb7c3ed61832c28c4047150d73a29a27ca8e967499b`, `index.wasm`
  `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`, `index.html`
  `e0a57e96dfd9122fcb09f9e9f51e04fe0904ba742e1a5328322cde54ff2947a8` (lista inteira em `build-web/SHA256SUMS.txt`).
- Servido pelo servidor de produção (`servidor-ws.js` + journal + VLAB real `a91c021c…`, fichas «acertam», monstros
  em auto), na mesma origem do `ws://…/ws`, pelo `arrancar-ensaio.cmd`. Conferido por `curl` com cache-busting, a
  partir do IP da rede (`http://192.168.1.38:8080`): os 7 ficheiros do jogo iguais byte a byte ao artefacto, `/qr` 200, `/?medir=1` 200;
  uma sonda pela rede entrou como «Arqueira de Bancada» pela senha e recebeu `ROOM_WELCOME` e `ROOM_SNAPSHOT seq=5`.

## Resultado (a preencher quando o ensaio correr)

| Campo | Valor |
|---|---|
| Data e hora do início | |
| Quem correu / quem tirou as fotos | |
| PC da mesa / IP do link | |
| Celular (modelo, Android, navegador) | |
| Commit do repositório no PC (`git rev-parse HEAD`) | |
| SHA-256 do `index.pck` servido (linha «export web» da janela) | |
| Pasta do resultado (`resultado-<data>`) | |

### Critérios

| # | Critério | Aceite | Resultado | Onde se vê |
|---|---|---|---|---|
| 1 | Entrou no lobby pelo QR/link, **sem instalar nada** | sim | | Foto 1 |
| 2 | **Turnos** jogados | ≥ 10 | | `conferir-ensaio.mjs` («turnos no journal») |
| 3 | Batalha acabada **por morte** (não por «Terminar») | sim | | journal |
| 4 | `fim {"desfecho":"morte"}` no journal (seq ___) | 1 só `fim`, desfecho morte | | `conferir-ensaio.mjs` |
| 5 | **Colocações duplicadas** | 0 ids, 0 casas | | `conferir-ensaio.mjs` |
| 6 | Wi-Fi desligado (hora PC) → ligado (hora PC) | 25 s | ___ → ___ | Passo 5 do guia |
| 7 | **Reconexão** (Wi-Fi ligado → mesa de volta, cronómetro) | ≤ 30 s | ___ s | cronómetro |
| 8 | Corte no registo do servidor (SAIU → ENTROU da Arqueira) | 1 corte com reentrada | ___ s | `conferir-ensaio.mjs` |
| 9 | **Nada se perdeu** (vida da Arqueira igual no celular e no PC depois de voltar; seq do journal contínuo) | sim | | Foto 3 + `conferir-ensaio.mjs` |
| 10 | **JSON da V1.0** do celular com todos os campos (`fps_mediana`, `fps_p5`, `chamadas_mediana`, `chamadas_max`, `gpu`, `viewport`, `dpr`, `quadros`, `plataforma`, `navegador`) | todos | FPS ___ / p5 ___ / chamadas ___ / gpu ___ | `conferir-ensaio.mjs` + Foto 4 |
| 11 | **4 fotos** (1 arena no celular; 2 lado a lado; 3 depois de voltar; 4 o JSON) | 4 | | `resultado-ensaio/` |
| 12 | Só fichas fictícias nas fotos | sim | | fotos |

### Saída do `conferir-ensaio.mjs` (colar inteira)

```
(por colar)
```

### Notas da pessoa (o que se viu, o que correu mal)

(por escrever)

**Veredicto:** (por lavrar — só depois de o ensaio correr)
