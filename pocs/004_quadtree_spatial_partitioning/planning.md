# Planning: 004_quadtree_spatial_partitioning

## Hipótese
Um Quadtree dinâmico em Zig pode gerenciar > 1.000.000 de pontos com tempo de inserção $O(\log N)$ e tempo de busca por área (culling) inferior a 0.5ms, permitindo navegação fluida em um canvas infinito.

## Retrospectiva & Síntese (Linhagem da POC)

Esta seção documenta a linhagem técnica desta POC e o reuso de validações anteriores.

### POCs Anteriores Referenciadas
- `pocs/001_libinput_tablet_input/` — **Retrospectiva:** Validou captura raw.
- `pocs/002_sokol_spsc_pipeline/` — **Retrospectiva:** Validou o pipeline thread-safe.
- `pocs/003_stroke_smoothing_savitzky_golay/` — **Retrospectiva:** Validou a suavização de traço (SG).

### Síntese de Reuso (O que será usado?)
- **Módulos/Arquivos:** Esta POC é uma validação de estrutura de dados pura. No entanto, ela "consome" conceitualmente os pontos processados pela POC 003. O módulo `QuadTree.zig` validado aqui será o próximo destino dos pontos suavizados no pipeline final.
- **Lógica/Padrões:** Uso de `ArenaAllocator` para gerir milhões de pontos, seguindo a filosofia de performance do Zig.
- **Por que é útil?** Validar a escala (1M pontos) garante que podemos gerenciar desenhos complexos no canvas infinito sem lag de culling.

## Escopo
- Estrutura de dados Quadtree genérica (suporte a tipos numéricos flexíveis).
- Inserção em massa de pontos simulados.
- Teste de "Range Query" (recuperar pontos dentro de um retângulo).
- Benchmark de performance (Query vs Inserção).
- **Sem visualização gráfica** (foco em lógica e RAM).

## Design Técnico
- **Recursive vs Iterative**: Recursivo para clareza inicial, com profundidade máxima controlada.
- **Memória**: Uso de um `ArenaAllocator` ou pool de nós para evitar fragmentação.
- **Sovereignty**: O Quadtree deve ser independente e facilmente integrável ao pipeline de renderização futuro.

## Critérios de Sucesso
- Inserção de 1.000.000 de pontos em menos de 500ms.
- Query de área (1000x1000 pixels) em menos de 0.5ms.

## Referências
- [Introduction to Quadtrees (Learn Computer Graphics)](https://learncomputergraphics.com/spatial-data-structures/quadtree/)
- [Quadtree Algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Quadtree)
- [Staggering performance in Zig (Zig News)](https://zig.news/)
