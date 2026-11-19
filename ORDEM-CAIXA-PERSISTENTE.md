# ORDEM CAIXA-PERSISTENTE — a escolha da caixa do Mestre vive no servidor (Claude 2, nuvem)

## Contexto
- A Ordem HUD fechou com pendências escritas; a Ordem INICIATIVA (hoje) pôs a ordem dinâmica dos turnos no servidor.
- Pendência (2) do HUD: «a escolha da caixa do Mestre vive só no cliente dele» — se ele sai e volta a meio da batalha, a escolha perde-se.
- Pendência (4) do HUD: «cores das caixas + fundo por omissão do retrato → tabela de apresentação dos DADOS».

## Objecto
1. A escolha da caixa do Mestre (que figura está seleccionada/mostrada na caixa) passa a ser guardada no estado do servidor, ao lado da ordem dinâmica que a INICIATIVA criou: ao reentrar a meio da batalha, o cliente do Mestre reconstrói a caixa COM a escolha que ele tinha feito.
2. Aplicar a tabela de apresentação entregue pela Ordem DADOS onde ela já define cores das caixas e fundo por omissão do retrato. Onde a tabela reservar um valor à palavra do Mestre (ex.: os hex finais dos 6 papéis da paleta), NÃO inventar: registar como pendência no ESTADO FINAL e deixar o valor actual.

## Regras
- Mudança mínima no cliente; o servidor é o dono do estado, como na INICIATIVA.
- Nenhum dado de vida/alma em campo novo (a sonda de privacidade tem de continuar verde).
- Provas: sair e reentrar a meio de uma batalha de bancada e a caixa reconstruída com a escolha anterior; capturas/relato em provas/ordem-caixa/.
- CI verde no código final. A fusão nesta linha junta fable/integracao-50 é a ÚLTIMA parte, depois das provas.

## Fecho
ESTADO FINAL escrito e commitado nesta branch: o que foi feito, provas, pendências exactas (incl. cada valor reservado ao Mestre que encontrares).
