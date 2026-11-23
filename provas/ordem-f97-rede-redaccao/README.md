# Ordem F97 — o remendo do CI (a guarda do log cru do canário, F71)

`remendo-ci-testes.yml.patch` acrescenta ao job `cliente` do `.github/workflows/testes.yml` o passo
«Guarda: 0 nomes inteiros no log cru do canário (F71)», a seguir ao passo do canário (e ao `setup-node`) e antes do
passo da redacção da F51, com `if: always()` e `working-directory: ${{ github.workspace }}`. O comando é o da ordem,
sem mudar uma letra.

O token do PC não tem o âmbito `workflow` (o `push` com o workflow mudado foi recusado), por isso o remendo vai para o
coordenador aplicar, como o da F51 (aplicado em `74f5fa9`, F65).

Aplicar, na raiz do repo:

    git apply provas/ordem-f97-rede-redaccao/remendo-ci-testes.yml.patch

O passo só lê `$RUNNER_TEMP/teste_nomes_relato.gd.log` (o `tee` fica) e conta os nomes inteiros com o `sobram` do
`redigir-nomes.mjs`, que lê os nomes das fichas e só imprime a contagem; sai com 1 se for > 0. Ensaiado no PC com o
mesmo comando: no log cru novo do canário dá «0 nome(s) inteiro(s)» e rc=0; no log cru de antes da F97 dá 7 e rc=1.
