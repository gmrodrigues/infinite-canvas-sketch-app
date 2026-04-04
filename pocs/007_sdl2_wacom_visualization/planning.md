# Planning: 007_sdl2_wacom_visualization

**Tipo:** Nano  
**Data Início:** 2026-04-04  
**Prazo Estimado:** 1 dia

## Hipótese

> Ao usar SDL2 para gerenciar janela e posição do cursor (via `SDL_MOUSEMOTION`), e libinput exclusivamente para pressure e tip-state, é possível implementar um visualizador de traço responsivo e correto sem precisar mapear coordenadas do tablet manualmente.

## Contexto

POC 005 falhou porque tentou mapear coordenadas físicas do tablet (mm) diretamente para pixels da janela via shader, gerando artefatos visuais e escala errada. O driver Wacom (via xf86-input-wacom ou libwacom) já mapeia o tablet para o espaço da tela automaticamente. SDL2 recebe essa posição via eventos de mouse como qualquer ponteiro.

## Escopo

**Esta POC VAI validar:**
- `SDL_MOUSEMOTION` como fonte de posição do cursor no canvas (já mapeado pelo driver)
- libinput como fonte de pressão (`get_pressure`) e tip-state (`get_tip_state`)
- Separação limpa: posição = OS/SDL, pressão+tip = libinput
- Renderização de múltiplos strokes com quebra correta (sentinel)
- Cursor visual: verde (hover) / vermelho (pressing)

**Esta POC NÃO VAI validar (fora de escopo):**
- Coordenadas físicas em mm (isso será POC futura para canvas infinito)
- Savitzky-Golay smoothing
- Buffers GPU (Sokol/OpenGL)

## Critérios de Sucesso

- [ ] Cursor segue o ponteiro do mouse mapeado pelo driver exatamente
- [ ] Traço aparece somente quando tip_down = true
- [ ] Pressão varia a intensidade visual do traço
- [ ] Múltiplos strokes separados (sem linhas entre eles)
- [ ] 60 FPS estável
- [ ] Zero crashes em 60 segundos de uso

## Referências a Consultar

- `pocs/001_libinput_tablet_input/` — extração de pressure e tip-state via libinput
- `pocs/002_sokol_spsc_pipeline/SpscQueue.zig` — padrão SPSC para thread-safe queue
