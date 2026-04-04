# Planning: 006_wacom_input_visualization

**Tipo:** Micro
**Data Início:** 2026-04-03
**Prazo Estimado:** 1-2 dias

## Hipótese

> Conseguimos capturar input real de tablet Wacom via libinput e visualizar em tempo real: um ponto flutuante (cursor) quando a caneta está no ar, e riscos contínuos quando a caneta toca o tablet.

## Escopo

**Esta POC VAI validar:**
- Captura de input Wacom via libinput (posição x, y, pressão)
- Renderização Sokol com janela nativa
- Cursor flutuante (ponto) quando `pressure == 0`
- Risco contínuo (linha) quando `pressure > 0`
- Loop de renderização estável a 60 FPS
- Input multi-threaded via SPSC queue

**Esta POC NÃO VAI validar (fora de escopo):**
- Quadtree ou particionamento espacial
- Suavização Savitzky-Golay
- Pan/zoom do canvas
- Múltiplos traços com persistência
- Exportação ou serialização

## Critérios de Sucesso

- [ ] Janela Sokol abre sem crashes
- [ ] Cursor flutuante aparece quando caneta está perto do tablet (sem tocar)
- [ ] Risco é desenhado quando caneta toca o tablet (pressure > 0)
- [ ] Posição do cursor/risco corresponde ao movimento real da caneta
- [ ] Pressão é mapeada visualmente (espessura ou cor do risco)
- [ ] 60 FPS estável por 5+ minutos
- [ ] Zero crashes ou memory leaks

## Retrospectiva & Síntese (Linhagem da POC)

### POCs Anteriores Referenciadas
- `pocs/001_libinput_tablet_input/` — **Retrospectiva:** Validou binding libinput + Wacom, leitura de pressure/position como f64.
- `pocs/002_sokol_spsc_pipeline/` — **Retrospectiva:** Validou SPSC queue wait-free para comunicação input → render.
- `pocs/005_sokol_real_render/` — **Retrospectiva:** Validou Sokol windowed mode com swapchain explícito.

### Síntese de Reuso (O que será usado?)
- **Módulos/Arquivos:** Lógica de libinput da POC 001 será copiada para input polling.
- **Lógica/Padrões:** SPSC queue da POC 002 será usada para comunicação entre threads.
- **Lógica/Padrões:** Setup de Sokol com swapchain da POC 005 será reutilizado.
- **Por que é útil?** Esta é a primeira POC que integra input real + renderização visual, validando o pipeline básico antes de adicionar complexidade (smoother, quadtree, etc).

## Referências Consultadas

- `pocs/001_libinput_tablet_input/main.zig` — para entender binding libinput
- `pocs/002_sokol_spsc_pipeline/main.zig` — para entender SPSC queue
- `pocs/005_sokol_real_render/main.zig` — para setup de Sokol windowed mode
