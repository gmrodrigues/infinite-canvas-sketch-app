# Planning: 004_quadtree_spatial_partitioning

## Hipótese
Um Quadtree dinâmico em Zig pode gerenciar > 1.000.000 de pontos com tempo de inserção $O(\log N)$ e tempo de busca por área (culling) inferior a 0.5ms, permitindo navegação fluida em um canvas infinito.

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
