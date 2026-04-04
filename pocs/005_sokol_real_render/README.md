# POC: 005_sokol_real_render

**Tipo:** Nano
**Status:** Aprovada ✅
**Período:** 2026-04-03 → 2026-04-03

## Hipótese

> Sokol-gfx com Zig 0.15.2 consegue criar uma janela nativa, configurar um pipeline de renderização e fazer renderização básica a 60 FPS sem crashes ou artefatos visuais.

## Como Executar

```bash
cd pocs/005_sokol_real_render/
zig build run
```

Para testar performance real:
```bash
zig build run -Doptimize=ReleaseSafe
```

## Resultado

### ✅ O que funcionou
- **Build Debug**: Sokol-gfx compilou corretamente com Zig 0.15.2
- **Build ReleaseSafe**: Compilou e rodou sem erros
- **Inicialização**: `sg.setup()` executou sem erros
- **Janela**: Sokol-app abriu janela X11 1280x720 sem crashes
- **Loop de renderização**: `sg.beginPass()` + `sg.endPass()` + `sg.commit()` rodou estavelmente por 5+ segundos
- **Dependência**: `floooh/sokol-zig` integrado via `build.zig.zon`
- **Shutdown**: `sg.shutdown()` executou sem erros (kill por timeout, sem panic)

### ⚠️ Issues resolvidos durante a POC
1. **Crash inicial no beginPass**: Causado por falta do campo `.swapchain` explícito
   - **Fix**: Adicionar `.swapchain = .{ .width, .height, .sample_count, .color_format, .depth_format }`
2. **API breaking changes**: sokol-zig mudou significativamente entre Zig 0.13 e 0.15
   - Campos removidos: `pass_pool_size`, `context_pool_size`, `usage = .STREAM`
   - Callbacks exigem `callconv(.c)` explícito
   - `sg.updateBuffer` agora usa `.data = sg.asRange()`
   - `beginPass` exige 8 elementos no array `.colors`

### Descobertas Técnicas
1. **Swapchain explícito obrigatório**: Sem `.swapchain` no `beginPass`, a validação interna do Sokol faz `SIGABRT`
2. **Shaders requerem sokol-shdc**: Para pipelines reais (não apenas clear screen), é necessário usar `sokol-shdc` para gerar `ShaderDesc` compatível com multi-backend
3. **Build.zig.zon**: Precisa de `.name = .enum_literal`, `.fingerprint`, e `.hash` para dependências Git
4. **Warnings de link em ReleaseSafe**: Normais para libs do sistema (.so) linkadas em archives .a

## Referências Usadas Como Inspiração

- `pocs/002_sokol_spsc_pipeline/` — configuração inicial de Sokol (modo headless)
- `docs/Tech.md` — seção 5 (Stack de Gráficos) para confirmação de Sokol como backend

## Decisão

- [x] **INTEGRAR** — Sokol windowed mode validado, pronto para pipeline completo
- [ ] **REVISAR** — Ajuste necessário: [especificar]
- [ ] **ABANDONAR** — Motivo: [especificar]

## Plano de Integração (somente se INTEGRAR)

- [ ] Mover configuração de Sokol para `src/render/sokol_setup.zig`
- [ ] Integrar sokol-shdc para compilação de shaders cross-platform
- [ ] Criar módulo de vertex streaming dinâmico em `src/render/vertex_streamer.zig`
- [ ] Integrar com input da POC 002 e smoother da POC 003
- [ ] Atualizar `docs/Tech.md` se a arquitetura mudou

## Learnings

- A API do sokol-zig passou por breaking changes entre Zig 0.13 e 0.15
- `sg.beginPass()` **exige** `.swapchain` explícito com width/height/format
- sokol-shdc é **obrigatório** para shaders multi-backend (GLSL → HLSL/MSL/WGSL automático)
- Sem shader compilado pelo shdc, não há como criar pipelines de renderização válidos
- build.zig.zon precisa de hash explícito e fingerprint para dependências Git
- Warnings de LLD sobre `.so` em archives são normais e não bloqueantes

