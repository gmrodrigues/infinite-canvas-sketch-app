# Planning: 002_sokol_spsc_pipeline

**Tipo:** Micro  
**Data Início:** 2026-04-03  
**Prazo Estimado:** 1–3 dias

## Hipótese

> Uma fila SPSC (Single-Producer Single-Consumer) wait-free em Zig é capaz de transportar eventos de tablet entre a thread de input (Libinput) e a thread de renderização (Sokol) sem causar micro-stuttering, mantendo a latência abaixo de 1ms.

## Por Que Esta POC?

Após validar que conseguimos ler os dados do tablet, precisamos garantir que o processamento desses dados não seja interrompido pelo ciclo de renderização e vice-versa. A thread de input deve rodar na frequência máxima do tablet (~200Hz+), enquanto a renderização roda no VSync (~60Hz ou mais). Uma SPSC queue lock-free é o padrão ouro para esta comunicação de baixa latência.

## Escopo

**Esta POC VAI validar:**
- Implementação de um `SpscQueue` genérico em Zig usando atomics (`std.atomic.Value`).
- Criação de uma thread dedicada para o loop `libinput`.
- Integração mínima com **Sokol Gfx** para renderizar os pontos capturados como pontos ou linhas simples na tela.
- Medição de "backpressure" ou "overflow" se a thread de renderização for lenta demais.

**Esta POC NÃO VAI validar:**
- Quadtrees (será outra POC).
- Filtros Savitzky-Golay (será outra POC).
- UI complexa.

## Critérios de Sucesso

- [ ] Compila e roda em modo multi-threaded.
- [ ] Renderiza na tela os movimentos da caneta em tempo real.
- [ ] Zero locks/mutexes no caminho crítico de captura de pontos.
- [ ] A thread de input não sofre atrasos mesmo se a renderização simular uma carga pesada (ex: `std.Thread.sleep`).

## Referências a Consultar

- `pocs/libinput_tablet_input/` — Reaproveitar o binding e setup do libinput.
- `docs/Tech.md` — Seção 2 (Comunicação Wait-Free).
- Repositório Sokol Zig: https://github.com/floooh/sokol-zig
