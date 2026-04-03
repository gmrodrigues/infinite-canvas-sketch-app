# POC: [Nome]

**Tipo:** Macro  
**Status:** Em Andamento | Aprovada | Abandonada  
**Período:** YYYY-MM-DD → YYYY-MM-DD

## Hipótese

> [Copiado de planning.md]

## Arquitetura da POC

```
[Diagrama ASCII do pipeline implementado localmente]

Ex: Input Sim → SPSC → Smoother → Quadtree → Sokol
```

## Como Executar

```bash
cd pocs/[nome_poc]/
zig build run
```

## Resultado

### Comportamento

[O sistema funcionou de ponta a ponta? Quais erros ou surpresas surgiram?]

### Métricas

| Métrica | Medido | Budget |
|---------|--------|--------|
| Input latency (input→render) | X ms | < 1 ms |
| FPS com dataset real | X | > 60 |
| Uso de memória (heap) | X MB | < 100 MB |
| Memory leaks | Sim/Não | Não |

### Demonstração

[Screenshot ou vídeo demonstrando o sistema funcionando]

## Referências Observadas

- `src/[arquivo].zig` — [o que foi observado; estrutura copiada localmente em `[arquivo_local].zig`]
- `pocs/[outra_poc]/` — [ideia específica observada e adaptada localmente]
- [Referência externa] — [o que foi usado]

## Edge Cases Descobertos

- [Edge case 1 — comportamento e impacto esperado na integração real]
- [Edge case 2]

## Decisão

- [ ] **INTEGRAR** — Subsistema validado. Ver plano abaixo.
- [ ] **REVISAR** — Ajuste necessário: [...]
- [ ] **ABANDONAR** — Motivo: [...]

## Plano de Integração (somente se INTEGRAR)

### Fase 1 — Estrutura
- [ ] Criar `src/[subsistema]/`
- [ ] Portar e adaptar módulos locais para padrão do projeto

### Fase 2 — Qualidade
- [ ] Remover prints de debug
- [ ] Garantir zero globals, arena allocators corretos
- [ ] Adicionar tests em `src/[subsistema]/`

### Fase 3 — Documentação
- [ ] Atualizar `docs/Tech.md` com arquitetura final

## Learnings

- [Aprendizado 1 — válido independente da decisão]
- [Aprendizado 2]
- [Aprendizado 3]
