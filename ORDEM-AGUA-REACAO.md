# ORDEM ÁGUA-REAÇÃO — as figuras mexem a água (Claude 1, nuvem)

## Contexto
- A Ordem 66 (água) fechou com a reserva escrita: «as figuras do jogo ainda não mexem a água». A Ordem NADO (hoje) ligou o estado de nado no lago: as figuras já nadam na funda e vadeiam na rasa.
- Falta a reacção VISUAL da água às figuras. É esta ordem.

## Objecto
Na bancada do lago (a mesma do NADO), a água reage às figuras:
1. Ao ENTRAR na água (rasa ou funda): anéis/ondulação a nascer no ponto de contacto e a expandir-se.
2. Ao MOVER-SE dentro de água (vadear ou nadar): ondulação contínua/rastro discreto à volta da figura, proporcional ao movimento; parada = a ondulação acalma até sumir.
3. Só visual: nenhuma regra de jogo muda; nenhum dado de vida/alma entra em campo novo.

## Regras
- Seguir os padrões já existentes no repo para efeitos de água/partículas (a chuva da Ordem 64 e o lago da 66 são a referência de casa); renderizador Compatibility; medir o custo no palco real (a régua da casa: efeito que não se mede no palco não entra).
- A reacção nasce da posição/estado que o NADO já expõe — não criar um segundo sistema de detecção de água.
- Provas: filme curto ou capturas antes/depois na bancada do lago (figuras a entrar, a vadear, a nadar e paradas), guardadas em provas/ordem-agua-reacao/.
- CI verde no código final. A fusão (merge) nesta linha junta fable/integracao-50 é a ÚLTIMA parte, depois das provas.
- Se alguma parte bloquear (ex.: o palco não expõe o ponto de contacto), regista a pendência exacta no ESTADO FINAL e entrega o resto — não inventes atalhos.

## Fecho
ESTADO FINAL escrito e commitado nesta branch: o que foi feito, provas, custo medido, pendências exactas.
