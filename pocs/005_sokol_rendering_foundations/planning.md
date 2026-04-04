# Planning: 005_sokol_rendering_foundations

## Hipótese
Ao integrar o pipeline SPSC (POC 002) com o filtro Savitzky-Golay (POC 003) e renderização direta via Sokol (GPU), podemos alcançar uma experiência de desenho com latência imperceptível e traço fluido, mesmo em resoluções 4K.

## Retrospectiva & Síntese (Linhagem da POC)

Esta seção documenta o que aprendemos nas validações anteriores e como isso será reutilizado aqui.

### POCs Anteriores Referenciadas
- `pocs/001_libinput_tablet_input/` — **Retrospectiva:** Validou a captura raw de eventos (X, Y, Pressure, Tilt) diretamente do driver do tablet no Linux. Demonstrou que o polling em thread separada é necessário para não perder pacotes em altas frequências (1kHz+).
- `pocs/002_sokol_spsc_pipeline/` — **Retrospectiva:** Validou o uso de `SpscQueue` (Single Producer Single Consumer) lock-free para transferir pontos entre threads sem bloqueios (wait-free). Demonstrou zero contenção entre a captura e a renderização.
- `pocs/003_stroke_smoothing_savitzky_golay/` — **Retrospectiva:** Validou que o algoritmo Savitzky-Golay remove o jitter do sensor mantendo a intenção do traço em sub-milissegundos (~3.5µs por ponto). Essencial para a sensação "premium" do desenho.
- `pocs/004_quadtree_spatial_partitioning/` — **Retrospectiva:** Validou que uma Quadtree em Zig gerencia 1.000.000 de pontos com queries de área em 45µs. Útil para culling de renderização em tempo real.

### Síntese de Reuso (O que será usado?)
- **Módulos/Arquivos:** 
    - `libinput` logic da POC 001 será adaptada para o thread de entrada principal.
    - `SpscQueue.zig` (POC 002) será o coração do pipeline de dados.
    - `SavitzkyGolay.zig` (POC 003) processará cada ponto vindo da fila antes de salvá-lo.
    - `QuadTree.zig` (POC 004) servirá como buffer espacial para armazenar e organizar os traços processados.
- **Lógica/Padrões:** Replicaremos o padrão de **Thread Sovereignty** (Input Thread vs Render Thread) e o uso de **ArenaAllocators** para gerenciar os lotes de vértices.
- **Por que é útil?** Já sabemos que cada componente performa bem isoladamente. Esta POC valida se a **orquestração** entre eles introduz lag ou gargalos de sincronização.

## Escopo
- **Integração de Pipeline**: Unir o thread de `libinput` com o thread de renderização da Sokol.
- **Desenho na GPU**: Implementar um "Path Renderer" simples usando buffers de vértices (GL_POINTS ou GL_LINE_STRIP).
- **Suavização Live**: Aplicar o filtro SG em tempo real conforme os pontos chegam na fila SPSC.
- **Visualização**: Janela interativa onde o usuário pode desenhar e ver o resultado suavizado.

## Critérios de Sucesso
- Desenho fluído com 60 FPS estáveis.
- Ausência de jitter visual no traço suavizado em tempo real.
- Latência visual imperceptível entre pen-touch e pixel-update.

## Referências Consultadas
- [Sokol Samples: Dynamic Buffers](https://floooh.github.io/sokol-html5/dyntex-safari.html)
- `SavitzkyGolay.zig` da POC 003.
- `SpscQueue.zig` da POC 002.
