#!/usr/bin/env python3
"""Confere mensagens soltas (um JSON por linha) contra os schemas do protocolo v2. I0004, 08/11/2026.

Uso (a partir de rascunhos/):
    python3 protocolo/ferramentas/validar-mensagens.py <ficheiro.jsonl> [--minimo N]

Serve para os comandos que o ecrã do Mestre do cliente Godot monta (testes/abrir_mestre.gd com
MESTRE_COMANDOS=<ficheiro>): cada um tem de passar no schema do seu `type`. Os schemas com ramos por
papel (ROOM_SNAPSHOT, MASTER_VIEW) não se usam aqui: isto é só para mensagens que SAEM do cliente.
Código de saída 0 se todas passarem (e houver pelo menos N), 1 se não.
"""
import json
import os
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

DIR_V2 = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'v2'))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    minimo = int(sys.argv[sys.argv.index('--minimo') + 1]) if '--minimo' in sys.argv else 1
    schemas = {}
    for nome in sorted(os.listdir(DIR_V2)):
        if nome.endswith('.schema.json'):
            with open(os.path.join(DIR_V2, nome), encoding='utf-8') as f:
                schemas[nome] = json.load(f)
    registo = Registry().with_resources([(k, Resource.from_contents(v)) for k, v in schemas.items()])
    falhas = 0
    total = 0
    with open(sys.argv[1], encoding='utf-8') as f:
        for n, linha in enumerate(f, 1):
            if not linha.strip():
                continue
            total += 1
            msg = json.loads(linha)
            nome = f"{msg.get('type')}.schema.json"
            if nome not in schemas:
                print(f'  FALHA linha {n}: sem schema para {msg.get("type")!r}')
                falhas += 1
                continue
            erros = list(Draft202012Validator(schemas[nome], registry=registo).iter_errors(msg))
            if erros:
                falhas += 1
                for e in erros:
                    print(f'  FALHA linha {n} {msg.get("type")}: {"/".join(map(str, e.path)) or "(raiz)"}: {e.message}')
            else:
                print(f'  ok    linha {n} {msg.get("type")} {msg.get("decisao", msg.get("op", ""))}')
    print(f'{total} mensagens, {falhas} falhas')
    if total < minimo:
        print(f'esperava pelo menos {minimo}')
        sys.exit(1)
    sys.exit(1 if falhas else 0)


if __name__ == '__main__':
    main()
