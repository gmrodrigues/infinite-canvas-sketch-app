# Planning: Sokol Real Render com Vertex Streaming Dinâmico

**Tipo:** Nano
**Data Início:** 2026-04-03
**Prazo Estimado:** 1-2 horas

## Hipótese

> Sokol-gfx com Zig 0.13+ consegue criar uma janela nativa, configurar um pipeline de renderização e fazer vertex streaming dinâmico de linhas (traços de caneta) a 60 FPS sem crashes ou artefatos visuais.

## Escopo

**Esta POC VAI validar:**
- Sokol-gfx abrindo janela nativa (GLFW ou backend nativo)
- Configuração de pipeline com vertex buffer dinâmico
- Desenho de linhas/traços com vértices atualizados a cada frame
- Pan/zoom básico via matriz de projeção
- Frame rate estável a 60 FPS

**Esta POC NÃO VAI validar (fora de escopo):**
- Input de tablet (Libinput) — dados serão simulados
- Quadtree ou particionamento espacial — poucos vértices
- Savitzky-Golay ou suavização — vértices diretos
- Multi-threading — single-threaded
- Exportação ou serialização

## Critérios de Sucesso

- [ ] Janela Sokol abre sem crashes em Linux (GL backend)
- [ ] Pipeline de renderização configura com vertex buffer dinâmico
- [ ] Traço de caneta simulado é renderizado como linha contínua
- [ ] Pan/zoom funciona via mouse (scroll + drag)
- [ ] Frame rate estável: 60 FPS por 5 minutos sem drops > 2 frames
- [ ] Zero memory leaks (GPA clean shutdown)
- [ ] Compila em Debug e ReleaseSafe sem warnings

## Retrospectiva & Síntese (Linhagem da POC)

### POCs Anteriores Referenciadas
- `pocs/002_sokol_spsc_pipeline/` — **Retrospectiva:** Validou Sokol em modo headless/simulado. Esta POC avança para renderização real com janela.

### Síntese de Reuso (O que será usado?)
- **Módulos/Arquivos:** Configuração de Sokol do `build.zig` da POC 002 será adaptada para windowed mode.
- **Lógica/Padrões:** O padrão de vertex buffer dinâmico será replicado na aplicação principal.
- **Por que é útil?** Sem validar Sokol real primeiro, a Macro POC 005 poderia falhar por motivos gráficos em vez de pipeline.

## Referências Consultadas

- `pocs/002_sokol_spsc_pipeline/build.zig` — consultado para configuração de dependências Sokol
- `docs/Tech.md` — seção 5 (Stack de Gráficos) para confirmar Sokol como backend recomendado
