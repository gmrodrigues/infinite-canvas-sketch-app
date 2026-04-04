# Planning: 003_stroke_smoothing_savitzky_golay

**Tipo:** Micro
**Data Início:** 2026-04-03
**Prazo Estimado:** 1-2 dias

## Hipótese

> O filtro de Savitzky-Golay com uma janela de 5 a 7 pontos é capaz de remover o ruído de alta frequência (jitter) do tablet Wacom em tempo real, mantendo a latência de processamento abaixo de 0.1ms por ponto e preservando a intenção do traço original (especialmente em curvas fechadas).

## Escopo

O que esta POC VAI validar:
- Implementação eficiente do algoritmo de Savitzky-Golay em Zig.
- Uso de coeficientes pré-calculados para janelas fixas (3, 5, 7, 9).
- Latência de processamento para fluxos de 200Hz+.
- Estabilidade matemática (evitar oscilações de Runge).

O que esta POC NÃO VAI validar (fora de escopo):
- Renderização visual (será validado via logs/csv de coordenadas).
- Integração com Quadtree.
- Pressão/Tilt (foco apenas na suavização posicional X/Y).

## Critérios de Sucesso

- [ ] Processamento de cada ponto em < 0.1ms.
- [ ] Redução visível de jitter em dados sintéticos ruidosos.
- [ ] Implementação genérica que aceite `f64` ou `f32`.
- [ ] Zero alocações no hot path (uso de buffers circulares ou stack).

## Referência Técnica: Funcionamento do Filtro

O filtro de **Savitzky-Golay** é um algoritmo de suavização digital que opera ajustando sucessivos subconjuntos de pontos de dados adjacentes a um polinômio de baixo grau pelo método dos mínimos quadrados (least squares).

### Como Funciona:
1. **Janela Móvel**: O filtro define uma janela de tamanho $2n+1$ pontos centrada no ponto atual.
2. **Ajuste Polinomial**: Para cada janela, ele calcula o polinômio (geralmente de 2º ou 3º grau) que melhor descreve esses pontos.
3. **Convolução**: A beleza do método é que o ajuste por mínimos quadrados pode ser pré-calculado como um conjunto de coeficientes fixos. A suavização torna-se uma simples **convolução**:
   $$ Y_t = \sum_{i=-n}^{n} C_i \cdot X_{t+i} $$
   Onde $C_i$ são os coeficientes de Savitzky-Golay.

### Por que usar no Infinite Canvas?
- **Preservação de Curvas**: Diferente de uma Média Móvel Simples (que "achata" picos e curvas fechadas), o Savitzky-Golay preserva melhor a curvatura original da caneta.
- **Eficiência**: Como os coeficientes são constantes para uma janela e grau fixos, o custo computacional é apenas algumas multiplicações e somas (SIMD-friendly).
- **Latência Determinística**: O atraso é fixo e igual à metade do tamanho da janela ($n$ pontos).

## Referências Consultadas

- **Original Paper**: Savitzky, A., & Golay, M. J. (1964). *Smoothing and Differentiation of Data by Simplified Least Squares Procedures*. Analytical Chemistry.
- **Numerical Recipes**: Press, W. H., et al. *Section 14.8: Savitzky-Golay Smoothing Filters*.
- **Wikipedia**: [Savitzky–Golay filter](https://en.wikipedia.org/wiki/Savitzky%E2%80%93Golay_filter).
- `docs/Tech.md` — Seção 3: Estabilização de Traço.

### Vídeos de Referência (Aprofundamento)
1. **[The idea of the Savitzky–Golay filter](https://www.youtube.com/watch?v=1SvDZPvUo_I)**: Uma animação brilhante de 1 minuto que ilustra perfeitamente o mecanismo de **janela deslizante** e **ajuste polinomial**.
2. **[Analytical Signal Processing Tutorial (Python SciPy)](https://www.youtube.com/watch?v=IhoO1lW0jfI)**: Tutorial prático detalhado sobre como os parâmetros (tamanho da janela e ordem do polinômio) afetam o resultado.
3. **[Smoothing your data with polynomial fitting](https://www.youtube.com/watch?v=0TSvo2hOKo0)**: Uma palestra técnica profunda sobre a teoria de processamento de sinais por trás do Savitzky-Golay.
