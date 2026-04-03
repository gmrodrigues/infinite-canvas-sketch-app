# POC: [Nome]

**Tipo:** Nano  
**Status:** Aprovada | Abandonada  
**Período:** YYYY-MM-DD (1 sessão)

## Hipótese

> [Copiado de planning.md]

## Como Executar

```bash
cd pocs/[nome_poc]/
zig build run
```

## Resultado

[O que foi observado. Seja específico: valores, comportamentos, erros.]

## Referências Observadas

- `src/[arquivo].zig` — observado para entender padrão X; adaptação copiada localmente em `[arquivo_local].zig`
- `pocs/[outra_poc]/` — ideia de Y reutilizada com adaptações

## Decisão

- [ ] **INTEGRAR** — Conceito validado. Plano de integração abaixo.
- [ ] **REVISAR** — Ajuste necessário: [...]
- [ ] **ABANDONAR** — Motivo: [...]

## Plano de Integração (somente se INTEGRAR)

- [ ] Criar `src/[subsistema]/[arquivo].zig`
- [ ] Adaptar para padrões do projeto (arena allocators, sem globals)
- [ ] Atualizar `docs/Tech.md` se a arquitetura mudou

## Learnings

- [Aprendizado — válido independente da decisão]
