# Backlog: 002_sokol_spsc_pipeline

## Em Andamento
- [ ] Criar estrutura base do diretório e `build.zig`

## A Fazer
- [ ] Implementar `SpscQueue` em Zig (baseado em atomics)
- [ ] Adaptar o loop de polling do `libinput_tablet_input` para rodar em uma thread separada
- [ ] Setup do **Sokol Gfx** (buffer de vértices dinâmico simples)
- [ ] Integrar: Fila recebe pontos do tablet → Thread de renderização consome e desenha
- [ ] Validar latência visual e ausência de stuttering
- [ ] Gerar Full Report no `README.md`

## Concluído
- [x] Criar `planning.md`
