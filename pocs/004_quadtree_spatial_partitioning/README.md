# POC 004: Quadtree Spatial Partitioning

Implementação e validação de uma estrutura de dados Quadtree para gerenciamento de milhões de pontos em um canvas infinito.

## Objetivos Alcançados
1.  **Estrutura de Dados**: Implementada `QuadTree.zig` com suporte a inserção recursiva e subdivisão dinâmica.
2.  **Gerenciamento de Memória**: Uso eficiente de `ArenaAllocator` para os nós, resultando em apenas ~89MB de RAM para 1.000.000 de pontos.
3.  **Performance de Escala**: Validada a hipótese de query sub-milissegundo para culling.

## Resultados de Benchmark (ReleaseSafe)
- **Quantidade de Pontos**: 1.000.000
- **Tempo de Inserção Total**: 648.80 ms
- **Média por Inserção**: 648.80 ns
- **Tempo de Query (1000x1000)**: **45.75 µs (0.0457 ms)** ✅
- **Meta de Query**: < 1000 µs (Alcançado com folga de 20x)

## Conclusões Técnicas
- O Quadtree é extremamente eficiente para o nosso caso de uso de "Infinite Canvas".
- A latência de query de 0.04ms permite que o motor de renderização realize o culling de milhões de pontos em cada frame sem impactar os 60 FPS (16.6ms).
- O uso de `Unmanaged ArrayList` no Zig 0.15.2 para os resultados de query minimiza o overhead de alocação se o buffer for reutilizado.

## Como Executar
```bash
zig build run -Doptimize=ReleaseSafe
```
