#!/usr/bin/env python3
"""Conferência dos schemas do protocolo v2 contra o tráfego real do servidor.

Uso (a partir de rascunhos/):
    PROTOCOLO_DUMP=/tmp/trafego.jsonl node --test --test-concurrency=1 servidor/testes/*.test.mjs
    python3 protocolo/ferramentas/conferir-schemas.py /tmp/trafego.jsonl

O que faz:
  1. Meta-valida cada *.schema.json (Draft 2020-12) e confirma que todos os $ref resolvem.
  2. Valida cada mensagem recolhida contra o schema do seu `type`.
  3. ROOM_EVENT e ROOM_SNAPSHOT: valida contra o ramo do PAPEL de quem recebeu (paraMestre, paraJogadora,
     paraEspectador) e confere a regra «os campos `propria` só se o evento é DELA»: um evento que não é da
     jogadora tem de caber também em paraEspectador (é o conferirPropria() que o ROOM_EVENT anuncia).
  4. Lista os `type` que o servidor usa e que não têm schema.
  5. Valida os exemplos de v2/exemplos/ (cada caso contra o schema do seu `type`).

As mensagens que ENTRAM e falham são contadas à parte: os testes mandam entradas inválidas de propósito
(o servidor recusa-as); servem para ver que o schema também as recusa. Só as que SAEM fazem falhar.

Precisa de `jsonschema` (>= 4.18) e `referencing`. Sai com código 1 se houver falhas.
Ordem 49 (B, achado M7 da Ordem 36): o tráfego vazio é FALHA (TRAFEGO-VAZIO), não sucesso calado — um ficheiro
sem nenhuma mensagem, ou sem nenhuma que SAIA do servidor (as únicas que fazem falhar), não confere nada.
Os intentId/cmdId de teste (\"it-1\", \"cmd-1\") não são UUID v4: essas falhas contam-se à parte
(ARTEFACTO-DE-TESTE) e não fazem falhar a conferência.
"""
import collections
import glob
import json
import os
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

AQUI = os.path.dirname(os.path.abspath(__file__))
DIR_V2 = os.path.join(AQUI, '..', 'v2')


def carregar_schemas():
    schemas = {}
    for f in sorted(glob.glob(os.path.join(DIR_V2, '*.schema.json'))):
        with open(f, encoding='utf-8') as fh:
            schemas[os.path.basename(f)] = json.load(fh)
    return schemas


def artefacto_de_teste(erro):
    # O padrão do UUID v4 falha com os ids determinísticos dos testes.
    return erro.validator == 'pattern' and '4[0-9a-fA-F]{3}' in str(erro.validator_value)


# Quem é o dono de um evento (o mesmo que EH_PROPRIO em servidor/nucleo/projecao.js).
DONO = {
    'movimento': lambda d, f: d.get('figuraId') == f,
    'ataque': lambda d, f: d.get('atacanteId') == f,
    'dano': lambda d, f: f in (d.get('alvoId'), d.get('autorId')),
    'estado': lambda d, f: d.get('figuraId') == f,
    'desgraca': lambda d, f: d.get('figuraId') == f,
    'cura': lambda d, f: d.get('curadorId') == f,
    'dano_ambiente': lambda d, f: d.get('alvoId') == f,  # ordem 13
}


def papel_de(nome):
    return 'mestre' if nome == 'mestre' else 'espectador' if nome == 'espectador' else 'jogadora'


def main(caminho):
    schemas = carregar_schemas()
    registo = Registry().with_resources([(k, Resource.from_contents(v)) for k, v in schemas.items()])
    falhas = 0
    for nome, s in schemas.items():
        try:
            Draft202012Validator.check_schema(s)
        except Exception as e:  # noqa: BLE001
            print(f'META {nome}: {e}')
            falhas += 1
    por_tipo = {nome[: -len('.schema.json')]: Draft202012Validator(s, registry=registo)
                for nome, s in schemas.items() if nome != 'comum.schema.json'}

    def ramo(nome_schema, papel):
        s = schemas[nome_schema]
        return Draft202012Validator({'$ref': f'{nome_schema}#/$defs/para{papel.capitalize()}'}, registry=registo)

    por_papel = {(t, p): ramo(f'{t}.schema.json', p)
                 for t in ('ROOM_EVENT', 'ROOM_SNAPSHOT') for p in ('mestre', 'jogadora', 'espectador')}
    figura_de = {}
    for f in sorted(glob.glob(os.path.join(DIR_V2, 'exemplos', '*.json'))):
        with open(f, encoding='utf-8') as fh:
            for caso in json.load(fh):
                m = caso['mensagem']
                for e in por_tipo[m['type']].iter_errors(m):
                    print(f'EXEMPLO {os.path.basename(f)} «{caso["caso"]}»: {e.message[:160]}')
                    falhas += 1
    vistos = collections.Counter()
    sem_schema = collections.Counter()
    erros = collections.defaultdict(collections.Counter)
    exemplo = {}
    artefactos = 0
    with open(caminho, encoding='utf-8') as fh:
        for linha in fh:
            if not linha.strip():
                continue
            reg = json.loads(linha)
            msg = reg['msg']
            tipo = msg.get('type', '?')
            vistos[(reg['sentido'], tipo)] += 1
            v = por_tipo.get(tipo)
            if v is None:
                sem_schema[(reg['sentido'], tipo)] += 1
                continue
            validadores = [(tipo, v)]
            if reg['sentido'] == 'sai' and tipo in ('ROOM_EVENT', 'ROOM_SNAPSHOT'):
                papel = papel_de(reg['papel'])
                validadores = [(f'{tipo}/{papel}', por_papel[(tipo, papel)])]
                if tipo == 'ROOM_SNAPSHOT' and isinstance(msg.get('propria'), dict):
                    figura_de[reg['papel']] = msg['propria'].get('figuraId')
                if tipo == 'ROOM_EVENT' and papel == 'jogadora':
                    dono = DONO.get(msg.get('tipo'))
                    f = figura_de.get(reg['papel'])
                    if dono and not dono(msg.get('dados') or {}, f):
                        validadores.append((f'{tipo}/outra-jogadora', por_papel[(tipo, 'espectador')]))
            rotulo_sentido = 'ENTRADA' if reg['sentido'] == 'entra' else 'SAIDA'
            for rotulo, val in validadores:
                for e in val.iter_errors(msg):
                    if artefacto_de_teste(e):
                        artefactos += 1
                        continue
                    caminho_erro = '/'.join(str(p) for p in e.absolute_path) or '(raiz)'
                    chave = f'{caminho_erro}: {e.message[:160]}'
                    erros[(rotulo_sentido, rotulo)][chave] += 1
                    exemplo.setdefault((rotulo, chave), msg)

    print('== Mensagens recolhidas (sentido, type) ==')
    for (sentido, tipo), n in sorted(vistos.items()):
        print(f'  {sentido:5} {tipo:22} {n}')
    print('\n== Sem schema ==')
    for (sentido, tipo), n in sorted(sem_schema.items()):
        print(f'  {sentido:5} {tipo:22} {n}')
    print('\n== Falhas nas mensagens que SAEM do servidor (contam) ==')
    for (sentido, tipo), cont in sorted(erros.items()):
        if sentido != 'SAIDA':
            continue
        for chave, n in cont.most_common():
            falhas += 1
            print(f'  {tipo}: {chave}  (x{n})')
    print('\n== Entradas recusadas pelo schema (informação: os testes mandam entradas inválidas de propósito) ==')
    for (sentido, tipo), cont in sorted(erros.items()):
        if sentido != 'ENTRADA':
            continue
        for chave, n in cont.most_common():
            print(f'  {tipo}: {chave}  (x{n})')
    print(f'\nArtefactos de teste (ids não-UUID) ignorados: {artefactos}')
    if sem_schema:
        falhas += 1
    nao_vistos = sorted(set(por_tipo) - {t for (_, t) in vistos})
    print('Schemas sem nenhuma mensagem no tráfego:', ', '.join(nao_vistos) or '(nenhum)')
    total = sum(vistos.values())
    saem = sum(n for (sentido, _), n in vistos.items() if sentido == 'sai')
    if saem == 0:
        # Ordem 49 (B, M7): sem mensagens que saem não há nada conferido; antes isto saía com 0.
        falhas += 1
        porque = 'a recolha não correu ou não escreveu nada' if total == 0 else 'só entradas: nada do servidor a conferir'
        print(f'\nFALHA TRAFEGO-VAZIO: {total} mensagens no tráfego, {saem} que saem do servidor, em {caminho} ({porque})')
    if os.environ.get('CONFERIR_EXEMPLOS'):
        for (tipo, chave), msg in exemplo.items():
            print(f'\n--- {tipo} | {chave}\n{json.dumps(msg, ensure_ascii=False)[:1500]}')
    return 1 if falhas else 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
