# POC 007: SDL2 Wacom Visualization

**Tipo:** Nano  
**Status:** Aprovada ✅  
**Período:** 2026-04-04 → 2026-04-04

## Hipótese

> Ao usar `SDL_MOUSEMOTION` para posição do cursor e libinput apenas para pressure + tip-state, é possível implementar um visualizador de traço correto sem mapear coordenadas do tablet manualmente.

## Como Executar

```bash
cd pocs/007_sdl2_wacom_visualization/
zig build run -Doptimize=ReleaseSafe
# ESC: sair | C: limpar canvas
```

## Resultado

### ✅ Highlights

1. **Arquitetura limpa**: Cada fonte de dado faz o que faz de melhor:
   - **OS/SDL** → posição do cursor (o driver Wacom já mapeou o tablet para a tela)
   - **libinput** → pressão + tip state (dados que o SDL não expõe)
2. **Cursor correto**: O traço segue exatamente o ponteiro do mouse, sem conversão manual de mm → pixels
3. **Múltiplos strokes**: Sentinels inseridos na quebra tip_up → sem linhas indesejadas entre strokes
4. **Visual responsivo**: Intensidade da cor varia com a pressão (pressure × 255)
5. **61 FPS estável**, `MaxRSS: 96M`
6. **Build limpo**: O SDL2 + libinput compila sem warnings relevantes com Zig 0.15.2

### ⚠️ Lowlights

1. **SDL2 não expõe pressão**: Nenhuma API SDL fornece pressão da caneta — libinput continua obrigatório
2. **Dois sistemas de input**: SDL para posição + libinput para pressão cria uma dependência de sincronização. Se o mouse SDL e o libinput ficam dessincronizados (ex: eventos chegam em ordens diferentes), o ponto pode ser registrado num frame errado
3. **Sem sub-frame precision**: SDL discretiza eventos por frame (16ms); libinput pode receber 200Hz. Pontos intermediários de pressão são descartados
4. **Mouse, não tablet**: SDL trata o Wacom como mouse genérico. Não há acesso a tilt, rotation ou tool_type via SDL

---

## SDL2 vs Sokol: Análise Comparativa

### SDL2 (`SDL_Renderer 2D`)

| Aspecto | Detalhe |
|---|---|
| **✅ Vantagem: Cursor fácil** | `SDL_MOUSEMOTION` já entrega x,y mapeados pelo driver — zero conversão |
| **✅ Vantagem: API simples** | `SDL_RenderDrawLine`, `SDL_RenderFillRect` — pronto para uso |
| **✅ Vantagem: Portabilidade** | Windows, Mac, Linux sem mudança de código |
| **❌ Limitação: Sem GPU real** | `SDL_Renderer` usa OpenGL/Metal internamente mas não expõe shaders |
| **❌ Limitação: Sem pressão** | Tablet pressure invisível para o SDL — precisa de libinput ou XInput complementar |
| **❌ Limitação: Sem anti-aliasing** | Linhas são aliased (serrilhadas) — sem suporte nativo a stroke width variável |
| **❌ Limitação: Escala limitada** | 100k+ linhas por frame degrada rapidamente sem culling — não escala para canvas infinito |

### Sokol (`sokol_gfx` + shader personalizado)

| Aspecto | Detalhe |
|---|---|
| **✅ Vantagem: GPU total** | Vertex buffer + shaders = traço anti-aliased, stroke variável, 1M+ pontos |
| **✅ Vantagem: Minimal** | Sem SDL como dependência — build mais leve |
| **✅ Vantagem: Cross-backend** | OpenGL 3.3, Metal, D3D11, WebGPU via `sokol-shdc` |
| **❌ Limitação: Cursor** | Mouse position requer X11/Wayland manual ou binding de `sapp_mouse_x()` — não usa driver |
| **❌ Limitação: Complexidade** | Vertex layout, shader uniform blocks, swapchain — mais código para o mesmo resultado |
| **❌ Limitação: Breaking API** | sokol-zig mudou muito entre Zig 0.13→0.15 (POC 005 falhou por isso) |

### Decisão para o Projeto

Para o **canvas infinito com GPU**, Sokol permanece a escolha correta. Mas a lição desta POC é:
> **Usar `SDL_GetMouseState` / `SDL_MOUSEMOTION` como fonte de posição mesmo dentro do app Sokol** — via `sapp_mouse_x()`/`sapp_mouse_y()` (equivalente no sokol-app), eliminando qualquer necessidade de mapear mm→pixels manualmente.

---

## Decisão

- [x] **INTEGRAR** — Padrão arquitetural validado: posição via OS, pressão via libinput

## Plano de Integração

- [ ] No próximo POC Sokol: usar `sapp_mouse_x()`/`sapp_mouse_y()` para posição
- [ ] Manter thread libinput apenas para pressure e tip_down
- [ ] Eliminar qualquer conversão mm→pixel manual

## Learnings

- O driver Wacom já faz o mapeamento tablet→tela — nunca re-mapear manualmente
- SDL2 é excelente para prototipagem 2D rápida, mas Sokol é necessário para GPU real
- A separação `posição = OS` / `pressão = libinput` é a arquitetura correta para tablets
