# Thanks: 002_sokol_spsc_pipeline

Este projeto baseia-se em conceitos fundamentais de computação paralela creditados a:

- **Charles E. Leiserson**: Pelos fundamentos de algoritmos concorrentes e estruturas wait-free que inspiram a nossa `SpscQueue`.
- **Andre Weissflog (@floooh)**: Pela arquitetura da `sokol_gfx` que permite atualizações de buffer de alto desempenho a cada frame.
- **Zig Standard Library Contributors**: Pela implementação robusta de `std.atomic`, permitindo comunicação lock-free idiomática em Zig.
