# Log: 003_stroke_smoothing_savitzky_golay

## 2026-04-03 21:15
- Início da implementação do `SavitzkyGolay.zig`.
- Mudança de design: Decidido usar buffers circulares fixos (`[window_size]T`) para evitar alocações e manter a sovereignty of dimension (instanciar um filtro por dimensão).
- Erro encontrado: `@memberDefinition` removido em versões recentes do Zig; substituído por `@This()`.
- Erro encontrado: `std.rand` removido em Zig 0.15.2; substituído por `std.Random`.
- Erro encontrado: `std.io.getStdOut()` com comportamento inconsistente em certas compilações; resolvido usando `std.debug.print` no test bench para focar na lógica.

## 2026-04-03 21:25
- Implementação do `BitMap.zig` (encoder BMP 1-bit monochrômatico).
- Plotagem de círculo com ruído ($\pm 15$px) vs filtrado.
- Resultados visuais confirmam redução drástica de jitter visual sem perda de forma.
- POC 003 Concluída e Auditada.
