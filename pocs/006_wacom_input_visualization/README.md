# POC: 006_wacom_input_visualization

**Tipo:** Micro
**Status:** ❌ FALHADA
**Período:** 2026-04-03 → 2026-04-03

## Hipótese

> Conseguimos capturar input real de tablet Wacom via libinput e visualizar em tempo real: um ponto flutuante (cursor) quando a caneta está no ar, e riscos contínuos quando a caneta toca o tablet.

## Resultado

### ❌ Falha Crítica: Renderização não aparece

Apesar do input Wacom funcionar (eventos detectados, pressão lida), **nenhuma renderização visual apareceu na tela**.

### Tentativas Falhas:
1. **Sokol-gfx + shaders**: Crash na criação de buffers/pipelines (API incompatível com Zig 0.15)
2. **Sokol + OpenGL imediato**: `glGetError() == 0` assertion failed (Sokol usa Core Profile, não suporta immediate mode)
3. **GLFW + OpenGL Core Profile**: Build OK, input OK, mas **nada aparece na tela** (possível problema de contexto GL ou coordinate system)

### O que funcionou:
- ✅ Libinput detecta tablet Wacom
- ✅ Eventos de posição e pressão são capturados
- ✅ SPSC queue transporta dados entre threads
- ✅ Janela abre (GLFW/Sokol)
- ✅ Loop roda a ~60 FPS

### O que NÃO funcionou:
- ❌ Cursor verde nunca apareceu
- ❌ Riscos brancos nunca apareceram
- ❌ Renderização OpenGL não é visível

### Causa Raiz Provável:
- Conflito entre Sokol-gfx (que gerencia contexto GL) e chamadas OpenGL diretas
- GLFW Core Profile requer VAOs/VBOs explícitos + shaders GLSL
- Coordinate system NDC (-1..1) pode estar invertido ou fora da viewport

## Decisão

- [ ] **INTEGRAR**
- [ ] **REVISAR**
- [x] **ABANDONAR** — Stack Sokol/GLFW muito complexa para visualização simples. Próxima POC usará **SDL2 puro** com OpenGL imediato.

## Learnings

- Sokol-gfx não é compatível com OpenGL immediate mode (`glBegin/glEnd`)
- GLFW + Core Profile 3.3 requer shaders GLSL compilados (não é trivial para POC)
- SDL2 suporta OpenGL 2.1 com immediate mode nativamente
- Para próxima POC: **SDL2 + OpenGL 2.1** é a stack mais simples para visualização imediata
