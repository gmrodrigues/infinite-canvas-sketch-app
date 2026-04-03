# Planning: [Nome da POC]

**Tipo:** Macro  
**Data Início:** YYYY-MM-DD  
**Prazo Estimado:** X dias

## Hipótese

> [Descreva o subsistema completo. Ex: "Um pipeline Libinput → SPSC → Quadtree → Sokol
> mantém < 1ms de latência e > 60 FPS com 100k pontos."]

## Contexto e Motivação

[Por que este subsistema precisa de uma Macro POC? Qual risco de integração prematura existia?]

## Arquitetura Planejada

```
[Diagrama ASCII dos componentes da POC e como se conectam]

Ex: Input Sim → SPSC → Smoother → Quadtree → Sokol
```

## Escopo

**Esta POC VAI validar:**
- [componente ou integração 1]
- [componente ou integração 2]

**Esta POC NÃO VAI validar (fora de escopo):**
- [item explicitamente excluído para POC futura]

## Critérios de Sucesso

- [ ] Aplicação roda standalone e é demonstrável
- [ ] [Critério de latência mensurável]
- [ ] [Critério de memória mensurável]
- [ ] [Critério visual/funcional mensurável]

## Referências a Consultar

- `src/[arquivo].zig` — estrutura a ser adaptada localmente
- `pocs/[outra_poc]/` — ideia de [X] reutilizada com adaptações locais
- Documentação externa: [links ou referências]
