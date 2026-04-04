---
name: poc_factory
description: >
  Sistema de validação por Proofs of Concept (POC) para o projeto Infinite Canvas.
  Toda nova funcionalidade DEVE ser validada em POC isolada antes de qualquer integração
  na aplicação principal. Cada POC é um mini-projeto autônomo com lifecycle completo.
version: 2.1
project: infinite-canvas-sketch-app
stack: Zig 0.13 + Sokol + Libinput/Wintab
---

# POC Factory — Infinite Canvas Sketch App

## Princípio Fundamental

> **NENHUM conceito entra na aplicação principal sem antes ser validado em POC.**

Toda funcionalidade nova segue obrigatoriamente esta sequência:

```
Ideia → POC isolada (mini-projeto completo) → Validação → Decisão explícita → Integração ou Abandono
```

---

## Modelo de Isolamento

O isolamento das POCs é de **soberania de diretório**, não de "cegueira".

### O que é PERMITIDO ✅

| Ação | POC → Projeto Principal | POC → Outra POC |
|------|------------------------|-----------------|
| **Ler** código como referência | ✅ Sim | ✅ Sim |
| **Copiar** estrutura ou lógica para dentro do próprio diretório | ✅ Sim | ✅ Sim |
| **Inspirar-se** em decisões arquiteturais | ✅ Sim | ✅ Sim |
| **Importar** diretamente via `@import` | ❌ Não | ❌ Não |
| **Modificar** arquivos fora do próprio diretório | ❌ Não | ❌ Não |
| **Alterar** documentação de outra POC | ❌ Não | ❌ Não |

### Regra de Ouro

> **"Você pode ver tudo. Você só pode tocar o que é seu."**

Uma POC pode ler `src/canvas/quadtree.zig` e copiar a ideia para `pocs/minha_poc/qt_local.zig`,
mas nunca pode fazer `@import("../../src/canvas/quadtree.zig")`.

Por quê? Porque a cópia local força a POC a ser executável de forma independente, sem depender
do estado atual do projeto principal — que pode estar em transição.

---

## Cada POC é um Mini-Projeto

Uma POC não é um arquivo solto. É um **mini-projeto com início, meio e fim**, contendo:

```
pocs/[ID]_[nome_poc]/
├── build.zig         # Build autossuficiente (não referencia build.zig raiz)
├── main.zig          # Entry point standalone
├── [outros .zig]     # Módulos internos copiados/adaptados localmente
│
```

### Regras de Nomeação
- Toda POC deve começar com um ID sequencial de 3 dígitos (ex: `001`, `002`).
- O nome deve ser descritivo e em snake_case.
- Exemplo: `pocs/001_libinput_tablet_input/`.

```
├── planning.md       # Hipótese, escopo, critérios de sucesso — feito ANTES de codar
├── backlog.md        # Tarefas da POC (mini-sprint)
├── log.md            # Diário de descobertas durante o desenvolvimento
├── README.md         # Resultado final: decisão e learnings (feito APÓS concluir)
└── Thanks.md         # Créditos e referências a produções intelectuais
```

### Lifecycle de uma POC

```
1. PLANEJAR    → Criar planning.md com hipótese e critérios claros
2. EXECUTAR    → Codar em isolamento, registrar descobertas em log.md
3. VALIDAR     → Verificar critérios de sucesso
4. DECIDIR     → Preencher README.md com resultado e decisão
5. ENCERRAR    → INTEGRAR (código vai para src/) ou ARQUIVAR/ABANDONAR

**Gerenciamento de Falhas:**
- Se uma POC falhar ou for abandonada, ela **NÃO** deve ser deletada.
- Renomeie o diretório para incluir o sufixo: `[ID]_[nome]-failed-[short-description]`.
- O `README.md` deve conter um "Failure Analysis" detalhado.
```

**Uma POC nunca fica "em aberto"** — ela termina com uma decisão explícita.

---

## Níveis de POC

### Nano POC (1–4 horas)

**Use quando:** Há uma dúvida técnica pontual ou necessidade de validar uma API/binding.

**Exemplos neste projeto:**
- "Libinput retorna pressão como f64 ou normalizado 0.0–1.0?"
- "sokol_gfx aceita `sg_update_buffer` sem recriar pipeline?"
- "Savitzky-Golay com janela 5 é estável com inputs de 200Hz?"

**Documentos obrigatórios:** `planning.md` + `README.md`  
**Documentos opcionais:** `log.md` (só se surgir algo inesperado)

**Template:** `pocs/_templates/nano/`

---

### Micro POC (1–3 dias)

**Use quando:** Validação de como dois subsistemas interagem.

**Exemplos neste projeto:**
- "O pipeline SPSC Lock-Free + Sokol update a cada frame funciona sem artefatos?"
- "Quadtree com `bring your own nodes` mantém performance com 100k pontos em f64?"
- "Bézier + Savitzky-Golay juntos produzem traço suave sem jitter?"

**Documentos obrigatórios:** `planning.md` + `backlog.md` + `log.md` + `README.md`

**Template:** `pocs/_templates/micro/`

---

### Macro POC (3–7 dias)

**Use quando:** Um subsistema inteiro precisa ser prototipado como aplicação standalone.

**Exemplos neste projeto:**
- "O pipeline completo Wacom → SPSC → Smoother → Quadtree → Sokol funciona de ponta a ponta?"
- "Canvas infinito com LOD de linhas e pan/zoom em f64 é viável?"
- "Export headless com ArenaAllocator dedicado não fragmenta o heap principal?"

**Documentos obrigatórios:** todos — `planning.md` + `backlog.md` + `log.md` + `README.md`  
**Entrega:** aplicação standalone demonstrável (screenshot ou vídeo no README.md)

**Template:** `pocs/_templates/macro/`

---

## Decision Matrix

| O que está sendo validado | Nível |
|---|---|
| Comportamento de uma função/API | Nano |
| Integração de dois subsistemas | Micro |
| Latência de ponta a ponta (input→render) | Micro |
| Subsistema completo novo | Macro |
| Mudança de arquitetura central | Macro |
| Performance com dados reais | Micro ou Macro |

---

## Workflow de Relatório (Full Report)

Ao concluir uma POC, é obrigatório gerar um **Full Report** que documente não apenas o sucesso/falha, mas as descobertas que impactam a arquitetura.

### Conteúdo do README.md (Relatório)

1.  **Hipótese Original**: Copiada do `planning.md`.
2.  **Como Executar**: Comandos exatos para reproduzir.
3.  **Resultado**: O que foi observado (métricas, logs, screenshots).
4.  **Descobertas Técnicas**: Gotchas, bugs corrigidos, mudanças de API (ex: compatibilidade com novas versões de Zig).
5.  **Decisão**: INTEGRAR, REVISAR ou ABANDONAR.
6.  **Plano de Integração**: Passos concretos se a decisão for integrar.
7.  **Segurança e Concorrência**: Como foram mitigados data races e crashes (ex: modelo atomics, safety-checks do Zig, stress tests).
8.  **Learnings**: Conhecimento acumulado para o futuro.

### Execução do Workflow de Relatório
- **Antes de Rodar**: Verificar se todos os critérios de sucesso do `planning.md` foram testados.
- **Durante o Teste**: Capturar logs relevantes e evidências de funcionamento (pressure, tilt, latency).
- **Após Rodar**: Preencher o `README.md` imediatamente enquanto as descobertas estão frescas.
- **Feedback Loop**: Notificar o Architect ou stakeholders sobre o resultado.

---

## Estrutura de Diretórios do Projeto

```
infinite-canvas-sketch-app/
├── src/                         # Aplicação principal
│   └── ...                      #   Só recebe código com POC aprovada
│
├── pocs/                        # Mini-projetos de validação
│   ├── _templates/              #   Templates por nível
│   │   ├── nano/
│   │   ├── micro/
│   │   └── macro/
│   ├── 001_libinput_tablet/       #   Exemplo: Nano POC validada
│   ├── 002_spsc_pipeline/     #   Exemplo: Micro POC em andamento
│   ├── [ID]_[nova_poc]/              #   Nova POC (mini-projeto completo)
│   └── 005_sokol_gfx-failed-gl-artifacts/ # Exemplo de falha arquivada
│
└── docs/
    ├── Tech.md
    └── pocs/                    #   Resultados de POCs encerradas (só leitura)
```

---

## Templates de Documentos

### `planning.md` — Preenchido ANTES de codar

```markdown
# Planning: [Nome da POC]

**Tipo:** Nano | Micro | Macro
**Data Início:** YYYY-MM-DD
**Prazo Estimado:** X horas/dias

## Hipótese

> [Uma frase: "Acredito que X se comporta assim: Y. Isso permite Z na aplicação."]

## Escopo

O que esta POC VAI validar:
- [item 1]

O que esta POC NÃO VAI validar (fora de escopo):
- [item 1]

## Critérios de Sucesso

- [ ] [Critério mensurável 1 — ex: latência < 1ms]
- [ ] [Critério mensurável 2]

## Retrospectiva & Síntese (Linhagem da POC)

Esta seção documenta a linhagem técnica desta POC, referenciando validações anteriores e o que será extraído delas.

### POCs Anteriores Referenciadas
- `pocs/[ID]_[nome]/` — **Retrospectiva:** O que foi demonstrado? (Ex: "Validou que o filtro SG reduz jitter em 80%").
- `pocs/[ID]_[outra]/` — **Retrospectiva:** [...]

### Síntese de Reuso (O que será usado?)
- **Módulos/Arquivos:** `[arquivo].zig` será copiado e adaptado para [finalidade].
- **Lógica/Padrões:** O padrão de [Threading/Memory] da POC [ID] será replicado aqui.
- **Por que é útil?** Explicação de como esses componentes aceleram ou tornam viável esta nova validação.

## Referências Consultadas

- `src/[arquivo].zig` — consultado para entender padrão X
- `pocs/[outra_poc]/` — consultado para inspiração em Y
```

---

### `backlog.md` — Mini-sprint da POC (Micro e Macro)

```markdown
# Backlog: [Nome da POC]

## Em Andamento
- [ ] [Tarefa atual]

## A Fazer
- [ ] Setup do build.zig
- [ ] Implementar subsistema A localmente
- [ ] Integrar A com B
- [ ] Medir métricas dos critérios de sucesso
- [ ] Preencher README.md com resultado

## Concluído
- [x] Criar planning.md
```

---

### `log.md` — Diário de descobertas (Micro e Macro)

```markdown
# Log: [Nome da POC]

## YYYY-MM-DD

### Descobertas
- [O que foi descoberto durante o trabalho]

### Problemas
- [Problema encontrado e como foi resolvido]

### Próximos Passos
- [O que fazer na próxima sessão]
```

---

### `README.md` — Resultado final (preenchido APÓS concluir)

```markdown
# POC: [Nome]

**Tipo:** Nano | Micro | Macro
**Status:** Aprovada | Abandonada
**Período:** YYYY-MM-DD → YYYY-MM-DD

## Hipótese

> [Copiado do planning.md]

## Como Executar

\```bash
cd pocs/[nome_poc]/
zig build run
\```

## Resultado

[O que foi observado. Métricas medidas.]

## Referências Usadas Como Inspiração

- `src/[arquivo].zig` — estrutura copiada e adaptada localmente
- `pocs/[outra_poc]/` — ideia X reutilizada com adaptações

## Decisão

- [ ] **INTEGRAR** — Conceito validado. Plano de integração abaixo.
- [ ] **REVISAR** — Ajuste necessário: [...]
- [ ] **ABANDONAR** — Motivo: [...]

## Plano de Integração (somente se INTEGRAR)

- [ ] Criar `src/[subsistema]/[arquivo].zig`
- [ ] Adaptar para padrão do projeto (arena allocators, sem globals)
- [ ] Atualizar `docs/Tech.md` se a arquitetura mudou

## Learnings

- [Aprendizado 1 — acumulado independente da decisão]
- [Aprendizado 2]
```

---

## Fluxo de Trabalho

```
1. Identificar incerteza ou feature nova
2. Escolher nível (Nano/Micro/Macro)
3. Determinar o próximo ID sequencial disponível em `pocs/`
4. Criar `pocs/[ID]_[nome_poc]/` com estrutura completa
5. Preencher `planning.md` (ANTES de codar)
5. Codar em isolamento — build.zig próprio, imports locais
   → Pode LER qualquer código do projeto como referência
   → Pode COPIAR lógica para dentro do próprio diretório
   → NUNCA importa diretamente de src/ ou outra POC
6. Registrar descobertas em log.md durante o trabalho
7. Validar critérios de sucesso do planning.md
8. Preencher README.md com resultado e decisão explícita
9. Se INTEGRAR: mover lógica para src/ com refatoração
10. Se ABANDONAR: POC fica em pocs/ como referência histórica
```

**Nunca pule do passo 4 para o 9 diretamente.**

### Workflow do Relatório Final (Step 8 Enhanced)
> Se a POC revelou quebras de contrato ou instabilidades (ex: C-ABI), o relatório DEVE detalhar as correções aplicadas para servir de guia na integração.

---

## Critérios de Aprovação

### Técnicos
- [ ] Executa sem crashes
- [ ] Demonstra o comportamento hipotizado
- [ ] Performance aceitável: input < 1ms, render < 16ms
- [ ] Memory leaks = zero

### Específicos deste Projeto
- [ ] Coordenadas de mundo em `f64` sem drift visível
- [ ] Nenhuma alocação em hot path de rendering
- [ ] Input pipeline não bloqueia thread de render

### Documentação
- [ ] `planning.md` preenchido antes do código
- [ ] `README.md` preenchido com resultado e decisão
- [ ] Seção de **Segurança e Concorrência** documentada (se aplicável ao nível)
- [ ] `Thanks.md` preenchido com créditos e referências

---

## Critérios de Abandono

1. **Hipótese rejeitada** — Comportamento observado invalida a abordagem
2. **Performance insuficiente** — Não atinge budget sem otimização desproporcional
3. **Complexidade excessiva** — Custo de integração supera o valor
4. **Abordagem melhor encontrada** — Outra POC (ou referência externa) mostrou solução superior
5. **C-ABI instável** — Binding se mostrou frágil ou não-documentado

Código abandonado **nunca é deletado** — fica em `pocs/` como experiência acumulada.

---

## Referências Cruzadas

- `workflow_orchestrator` — Processo geral de gestão de features
- `docs/Tech.md` — Especificação técnica que as POCs validam na prática

---

**Version:** 2.1
**Project:** infinite-canvas-sketch-app
**Metodologia:** POC-First — Mini-projetos autônomos com soberania de diretório
