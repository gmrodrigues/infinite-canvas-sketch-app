# POC: 001_libinput_tablet_input

**Tipo:** Nano
**Status:** Aprovada ✅
**Período:** 2026-04-03 → 2026-04-03

## Hipótese

> Usando `@cImport` + C-ABI do Zig 0.13, conseguimos abrir um dispositivo Wacom/tablet via `libinput` e ler eventos de pressão (`pressure`), posição (`x`, `y`) e inclinação (`tilt_x`, `tilt_y`) em formato `f64`, sem crash e com valores na faixa esperada.

## Como Executar

```bash
cd pocs/libinput_tablet_input/
zig build run
```
*Nota: Pode ser necessário `sudo` dependendo das permissões de `/dev/input/`.*

## Resultado

A POC foi validada com sucesso usando um tablet **Wacom Intuos S**. 

### Descobertas Técnicas (Zig 0.15.2)
Embora planejada para Zig 0.13.0, a execução no ambiente atual (Zig 0.15.2) revelou três mudanças necessárias na C-ABI do Zig:
1. **Calling Convention**: O identificador `.C` foi alterado para `.c` (minúsculo).
2. **Ponteiros C**: O parâmetro `path` no callback de abertura (`open_restricted`) deve ser explicitamente `[*c]const u8` para compatibilidade com o binding gerado pelo `@cImport`.
3. **Thread Sleep**: `std.time.sleep` foi movido para `std.Thread.sleep`.

### Validação de Hardware
- **Detecção**: O dispositivo foi identificado corretamente como `Wacom Intuos S Pen`.
- **Eixos**: Posição (`x`, `y`), `pressure` e `tilt` foram lidos como `f64`.
- **Estabilidade**: O loop de eventos rodou sem crashes ou memory leaks detectados.

## Decisão

- [x] **INTEGRAR** — O binding com `libinput` é sólido e os dados são normalizados corretamente pelo driver/biblioteca.

## Plano de Integração

- [ ] Mover a lógica de inicialização do contexto `libinput` para `src/input/linux_libinput.zig`.
- [ ] Implementar a interface de `InputProvider` definida no `Tech.md`.
- [ ] Garantir que o loop de polling rode em uma thread dedicada para não sancionar o framerate de renderização.

## Learnings

- A C-ABI do Zig está evoluindo rápido; POCs são essenciais para detectar quebras de API antes de contaminar o projeto principal.
- `libinput` via `udev` é a forma mais direta e robusta de obter dados de alta precisão de tablets no Linux moderno.
