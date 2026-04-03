# POC: [Nome]

**Tipo:** Micro  
**Status:** Em Andamento | Aprovada | Abandonada  
**Período:** YYYY-MM-DD → YYYY-MM-DD

## Hipótese

> [Copiado de planning.md]

## Como Executar

```bash
cd pocs/[nome_poc]/
zig build run
# ou:
zig build test
```

## Resultado

### Comportamento

[O sistema se comportou como esperado? Quais surpresas surgiram?]

### Métricas

| Métrica | Medido | Budget |
|---------|--------|--------|
| Latência A→B | X µs | < Y µs |
| Uso de memória | X KB | < Y KB |

## Referências Observadas

- `src/[arquivo].zig` — [o que foi observado; ideia copiada localmente em `[arquivo_local].zig`]
- `pocs/[outra_poc]/` — [estrutura observada e adaptada localmente]

## Edge Cases Descobertos

- [Edge case 1 — o que aconteceu]
- [Edge case 2]

## Decisão

- [ ] **INTEGRAR** — Conceito validado. Ver checklist abaixo.
- [ ] **REVISAR** — Ajuste necessário: [...]
- [ ] **ABANDONAR** — Motivo: [...]

## Checklist de Integração (somente se INTEGRAR)

- [ ] Criar `src/[subsistema]/`
- [ ] Refatorar para padrão do projeto (sem globals, arena allocators)
- [ ] Adicionar tests em `src/[subsistema]/`
- [ ] Atualizar `docs/Tech.md` se a arquitetura mudou

## Learnings

- [Aprendizado 1]
- [Aprendizado 2]
