# Planning: libinput_tablet_input

**Tipo:** Nano  
**Status:** FINALIZADA ✅  
**Data Início:** 2026-04-03  
**Data Conclusão:** 2026-04-03  
**Prazo Estimado:** 2–4 horas

## Hipótese

> Usando `@cImport` + C-ABI do Zig 0.13, conseguimos abrir um dispositivo Wacom/tablet via
> `libinput` e ler eventos de pressão (`pressure`), posição (`x`, `y`) e inclinação (`tilt_x`,
> `tilt_y`) em formato `f64`, sem crash e com valores na faixa esperada.

## Por Que Esta é a Primeira POC

Esta é a fundação de toda a arquitetura. Se o binding `libinput` → Zig não funcionar no hardware
real, ou se os valores retornados forem brutos/normalizados de forma diferente do esperado,
**90% das decisões técnicas do `Tech.md` precisam ser revistas** antes de qualquer outra linha
de código ser escrita.

Riscos que esta POC mitiga:
- `@cImport` com headers de `libinput` pode ter incompatibilidades com Zig 0.13
- `udev` pode exigir permissões especiais para abrir o dispositivo de tablet
- Os valores retornados podem ser normalizados (0.0–1.0) ou em unidades de hardware — impacta todo o pipeline
- O dispositivo tablet pode não expor todos os eixos como esperado no Linux

## Escopo

**Esta POC VAI validar:**
- Compilar um binding `@cImport` com `libinput.h` e `libudev.h` em Zig 0.13
- Abrir o backend `libinput` com `libinput_udev_create_context`
- Detectar um dispositivo tablet conectado
- Ler eventos de loop principal: `LIBINPUT_EVENT_TABLET_TOOL_AXIS` e `LIBINPUT_EVENT_TABLET_TOOL_TIP`
- Imprimir `x`, `y`, `pressure`, `tilt_x`, `tilt_y` com tipo `f64` no terminal
- Confirmar faixa de valores (ex: pressure é 0.0–1.0? ou 0–2048?)

**Esta POC NÃO VAI validar (fora de escopo):**
- SPSC queue
- Thread separada para polling
- Renderização (sem janela, sem Sokol)
- Smoothing ou filtros

## Critérios de Sucesso

- [x] Compila sem erros com `zig build`
- [x] Detecta o tablet sem crash ao iniciar
- [x] Ao mover/pressionar a caneta, imprime eventos no terminal
- [x] Os valores de `pressure` são `f64` e variam visivelmente com a pressão real aplicada
- [x] Os valores de `x` e `y` aumentam/diminuem conforme o movimento da caneta

## Referências a Consultar

- `docs/Tech.md` → Seção 2 (Libinput, Wintab, C-ABI)
- Documentação oficial libinput: https://wayland.freedesktop.org/libinput/doc/latest/
- Repositório de referência de binding Zig+C: nenhum disponível — este é o risco

## Estrutura da POC

```
pocs/libinput_tablet_input/
├── build.zig        # Linka com libinput e libudev
├── main.zig         # Loop de eventos, print de eixos
└── planning.md      # Este arquivo
```
