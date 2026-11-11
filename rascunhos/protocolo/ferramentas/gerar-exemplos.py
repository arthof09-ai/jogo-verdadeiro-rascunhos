#!/usr/bin/env python3
"""Gera protocolo/v2/exemplos/<TYPE>.json a partir do tráfego REAL dos testes do servidor.

Uso (a partir de rascunhos/):
    PROTOCOLO_DUMP=/tmp/trafego.jsonl node --test --test-concurrency=1 servidor/testes/*.test.mjs
    python3 protocolo/ferramentas/gerar-exemplos.py /tmp/trafego.jsonl

Cada ficheiro é uma lista de casos {caso, sentido, papel, mensagem}. Os exemplos vêm do servidor, não
são escritos à mão (excepto os de MASTER_CONFIRM_DICE e MASTER_EXPORT, que nenhum teste gera ainda).
Limpeza: os canários dos testes (CANARIO-...) passam a EXEMPLO-..., as senhas de teste passam a
marcadores, o PIN de teste passa a 12345678, e os ids de intenção passam a UUID v4 fixos (o protocolo
exige UUID v4 no aparelho).
Todos os casos são validados contra os schemas antes de se escreverem.
"""
import json
import os
import re
import sys
import uuid

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

AQUI = os.path.dirname(os.path.abspath(__file__))
DIR_V2 = os.path.normpath(os.path.join(AQUI, '..', 'v2'))
DIR_EX = os.path.join(DIR_V2, 'exemplos')
SEGREDOS = {'90210777': '12345678', 'CANARIO-SENHA-H': '<senha-da-heroina>',
            'CANARIO-SENHA-A': '<senha-da-aliada>', 'CANARIO-SENHA-E': '<senha-do-espectador>'}
RE_ID_TESTE = re.compile(r'^(it|ia|cmd|fc|aliada|golpe|oculto)-[A-Za-z0-9-]+$')


def uuid4_fixo(texto):
    u = uuid.UUID(bytes=uuid.uuid5(uuid.NAMESPACE_URL, 'jogo-verdadeiro/' + texto).bytes, version=4)
    return str(u)


def limpar(valor, chave=None):
    if isinstance(valor, dict):
        return {k: limpar(v, k) for k, v in valor.items()}
    if isinstance(valor, list):
        return [limpar(v, chave) for v in valor]
    if isinstance(valor, str):
        if valor in SEGREDOS:
            return SEGREDOS[valor]
        if chave in ('intentId', 'intentIdOrigem') and RE_ID_TESTE.match(valor):
            return uuid4_fixo(valor)
        return valor.replace('CANARIO', 'EXEMPLO')
    return valor


def chave_caso(sentido, papel, msg):
    t = msg['type']
    papel_g = 'mestre' if papel == 'mestre' else 'espectador' if papel == 'espectador' else 'jogadora'
    if t == 'ROOM_EVENT':
        return (t, msg['tipo'], papel_g)
    if t in ('ROOM_SNAPSHOT', 'ROOM_WELCOME'):
        return (t, papel_g)
    if t == 'ROOM_RECEIPT':
        return (t, msg.get('estado'), 'revertida' if msg.get('revertidaEm') else '')
    if t == 'ROOM_INTENT':
        return (t, msg['acao'].get('tipo'))
    if t == 'MASTER_CARD':
        return (t, msg.get('tipo'))
    if t in ('ROOM_REJECT', 'ERRO'):
        return (t, msg.get('motivo') or msg.get('codigo'))
    if t == 'MASTER_SUPERVISOR':
        return (t, msg.get('op'))
    if t == 'ROOM_JOIN':
        return (t, msg.get('papel'))
    return (t,)


def main(caminho):
    schemas = {}
    for f in os.listdir(DIR_V2):
        if f.endswith('.schema.json'):
            with open(os.path.join(DIR_V2, f), encoding='utf-8') as fh:
                schemas[f] = json.load(fh)
    registo = Registry().with_resources([(k, Resource.from_contents(v)) for k, v in schemas.items()])
    val = {k[: -len('.schema.json')]: Draft202012Validator(v, registry=registo) for k, v in schemas.items()}

    casos = {}
    with open(caminho, encoding='utf-8') as fh:
        for linha in fh:
            reg = json.loads(linha)
            msg = limpar(reg['msg'])
            if reg['papel'].startswith('falso'):
                continue  # tentativas falhadas de propósito (PIN errado): não servem de exemplo
            k = chave_caso(reg['sentido'], reg['papel'], msg)
            if k in casos or msg['type'] not in val:
                continue
            if list(val[msg['type']].iter_errors(msg)):
                continue  # entradas inválidas de propósito nos testes: não servem de exemplo
            descricao = ' · '.join(str(x) for x in k[1:] if x) or msg['type']
            casos[k] = {'caso': descricao, 'sentido': 'cliente → servidor' if reg['sentido'] == 'entra' else 'servidor → cliente',
                        'papel': reg['papel'], 'mensagem': msg}

    # Os dois que nenhum teste gera ainda (escritos à mão a partir do schema).
    casos[('MASTER_CONFIRM_DICE',)] = {'caso': 'o Mestre aceita os dados físicos da jogadora (escrito à mão)',
        'sentido': 'cliente → servidor', 'papel': 'mestre',
        'mensagem': {'v': 2, 'type': 'MASTER_CONFIRM_DICE', 'roomId': 'sala-teste', 'cmdId': 'cmd-41', 'revision': 12,
                     'intentId': uuid4_fixo('dados-1'), 'aceitar': True}}
    casos[('MASTER_EXPORT',)] = {'caso': 'exportação do journal, só ao Mestre (escrito à mão; o conteúdo real é do journal)',
        'sentido': 'servidor → cliente', 'papel': 'mestre',
        'mensagem': {'v': 2, 'type': 'MASTER_EXPORT', 'roomId': 'sala-teste', 'marca': 'MESTRE-ONLY',
                     # Ordem 21 (N19-1): o texto de journal.exportar(), como o servidor o manda (corpo, assinatura).
                     'conteudo': '<corpo canónico do journal>\n<sha256:… ou hmac-sha256:…>\n'}}

    por_tipo = {}
    for k, c in casos.items():
        erros = list(val[c['mensagem']['type']].iter_errors(c['mensagem']))
        if erros:
            print('EXEMPLO INVÁLIDO', k, erros[0].message)
            return 1
        por_tipo.setdefault(c['mensagem']['type'], []).append(c)
    os.makedirs(DIR_EX, exist_ok=True)
    for t, lista in sorted(por_tipo.items()):
        lista.sort(key=lambda c: (c['papel'], c['caso']))
        with open(os.path.join(DIR_EX, t + '.json'), 'w', encoding='utf-8') as fh:
            json.dump(lista, fh, ensure_ascii=False, indent=2)
            fh.write('\n')
        print(f'{t:22} {len(lista)} caso(s)')
    faltam = sorted(set(val) - set(por_tipo) - {'comum'})
    print('Sem exemplo:', ', '.join(faltam) or '(nenhum)')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
