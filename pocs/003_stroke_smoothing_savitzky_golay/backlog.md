# Backlog: 003_stroke_smoothing_savitzky_golay

## Em Andamento
- [ ] Criar estrutura base do diretório e `build.zig`

## A Fazer
- [ ] Implementar `SavitzkyGolay.zig` (módulo core do filtro).
- [ ] Implementar coeficientes fixos para janelas 5 e 7.
- [ ] Criar gerador de dados ruidosos para testes (simular jitter).
- [ ] Implementar benchmark de latência (pontos/segundo).
- [ ] Validar continuidade de borda (pontos iniciais e finais).
- [ ] Documentar resultados no `README.md`.

## Concluído
- [x] Criar `planning.md`.
- [x] Definir hipótese de janela (5-7 pontos).
