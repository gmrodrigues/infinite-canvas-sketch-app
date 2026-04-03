# Skills — Infinite Canvas Sketch App

**Versão:** 2.0  
**Projeto:** infinite-canvas-sketch-app  
**Stack:** Zig 0.13 + Sokol + Libinput/Wintab + Wacom  
**Metodologia:** POC-First — nenhum conceito entra em `src/` sem POC aprovada

---

## 📦 Visão Geral

Skills e workflows do projeto **Infinite Canvas Sketch App** — engine de desenho de alta performance com suporte a tabletes Wacom.

**Stack:** Zig 0.13 + Sokol (gfx) + Libinput/Wintab (Wacom) + MessagePack  
**Metodologia Central:** POC-First — toda funcionalidade nova é validada em POC isolada antes de integrar  
**Workflows:** Lone Wolf (padrão para este projeto solo)

---

## 📚 Skills Incluídas

| Skill | Descrição | Quando Usar |
|-------|-----------|-------------|
| **[workflow_orchestrator]** | Workflows Corporate e Lone Wolf, templates, POCs | Setup do projeto, gestão de features |
| **[tech_stack_zig_raylib]** | Zig, Raylib, Nuklear, SDL2, DOD, memória | Implementação técnica |
| **[style_guide_retro_fps]** | Estética 90s, paletas, resolução, sprites | Direção de arte, UI |
| **[game_mechanics_dod]** | ECS simplificado, sistemas, física | Mecânicas de jogo |
| **[poc_factory]** | Nano/Micro/Macro POCs, validação | Novas features, experimentos |
| **[editor_ui_standards]** | UI de editores, ZUI, componentes | Ferramentas internas |
| **[asset_pipeline_qoi]** | QOI, YAML, sprites 8-direções | Pipeline de assets |

[workflow_orchestrator]: ./workflow_orchestrator/SKILL.md
[tech_stack_zig_raylib]: ./tech_stack_zig_raylib/SKILL.md
[style_guide_retro_fps]: ./style_guide_retro_fps/SKILL.md
[game_mechanics_dod]: ./game_mechanics_dod/SKILL.md
[poc_factory]: ./poc_factory/SKILL.md
[editor_ui_standards]: ./editor_ui_standards/SKILL.md
[asset_pipeline_qoi]: ./asset_pipeline_qoi/SKILL.md

---

## 🚀 Quick Start — Criando uma POC

```bash
# 1. Escolha o template pelo nível (nano/micro/macro)
cp -r .agents/poc_factory/templates/nano/ pocs/minha_poc/
# ou use os templates em pocs/_templates/

# 2. Edite main.zig e README.md com sua hipótese

# 3. Execute em isolamento total
cd pocs/minha_poc/
zig build run

# 4. Documente resultado e tome a decisão em README.md
# 5. Se INTEGRAR: mova a lógica para src/ com refatoração
```

> **Regra absoluta:** Nunca edite `src/` para "testar" algo antes de uma POC aprovada.

---

## 📋 Estrutura de Diretórios

```
infinite-canvas-sketch-app/
├── .agents/                   # Skills e workflows
│   ├── poc_factory/           #   ← Skill principal: POC-First
│   ├── workflow_orchestrator/ #   Templates e processo
│   └── ...
│
├── src/                       # Aplicação principal (só entra código com POC aprovada)
│   ├── main.zig
│   ├── input/                 #   Wacom / Libinput / SPSC
│   ├── canvas/                #   Quadtree, coordenadas f64
│   ├── render/                #   Sokol, vertex streaming
│   └── export/                #   Headless render, serialização
│
├── pocs/                      # POCs isoladas (NUNCA importadas por src/)
│   ├── _templates/            #   nano/ micro/ macro/
│   ├── [nome_poc]/            #   Cada POC: main.zig + build.zig + README.md
│   └── ...
│
└── docs/
    ├── PRD.md
    ├── Tech.md
    └── pocs/                  #   Resultados de POCs (só documentação)
```

---

## 🎯 Workflows

### Corporate Protocol

**Melhor para:**
- Equipes (2+ pessoas)
- Projetos de longo prazo (> 3 meses)
- Múltiplas features interdependentes
- Consistência arquitetural rigorosa

**Processo:**
```
Ideia → RRA + PlantUML → Sprint Planning → Implementation Report
  → Código → Drift Analysis → Sprint Retro → Audit Trail
```

**Templates:**
- `requisition_form.md`
- `implementation_report.md`
- `drift_report.md`
- `sprint_planning.md`
- `sprint_retro.md`
- `memorandum.md`

### Lone Wolf

**Melhor para:**
- Desenvolvimento solo
- Prototipagem rápida / game jams
- Features isoladas
- Prazos apertados

**Processo:**
```
Ideia → Backlog → Implementation Notes → Código
  → Quick Drift Check (5 min) → Done
```

**Templates:**
- `lone_wolf_backlog.md`
- `lone_wolf_debt.md`
- `implementation_notes.md`
- `quick_drift_check.md`
- `session_notes.md`

---

## 🔬 POC Factory

### Níveis de POC

| Nível | Duração | Complexidade | Entrega |
|-------|---------|--------------|---------|
| **Nano** | 1-2h | Baixa | Código + 1 página |
| **Micro** | 1-2 dias | Média | Código + 2-3 páginas + checklist |
| **Macro** | 3-5 dias | Alta | RRA + código + review + drift report |

### Decision Matrix

```
Complexidade Baixa + Risco Baixo  → Nano POC
Complexidade Baixa + Risco Alto   → Nano + Micro
Complexidade Média                → Micro POC
Complexidade Alta                 → Macro POC
```

---

## 🎨 Estética Retro FPS

### Resoluções

| Nome | Resolução | Uso |
|------|-----------|-----|
| Potato | 320x200 | Engine principal |
| Classic | 640x400 | Editores, UI |
| Enhanced | 640x480 | Menus, cutscenes |

### Scaling

```zig
// ✅ CORRETO: Integer scaling
const scale: u32 = 3; // 320x200 → 960x600

// ❌ ERRADO: Não-integer (causa blur)
const scale: f32 = 2.5;
```

### Paleta

- **Max cores simultâneas:** 64-256
- **UI cores:** Máximo 7
- **Cores principais:** Corporate Cyan (#00FFFF), Doom Red (#FF0000)

### Sprites

- **8 direções:** N, NE, E, SE, S, SW, W, NW
- **Tamanhos:** Player (64x64), Enemy (48x48), Icon (16x16)
- **Formato:** QOI com YAML metadata

---

## 💾 Tech Stack

### Zig

- **Versão:** 0.11+
- **Memória:** Arena (frame), GPA (persistente), Pool (entidades)
- **DOD:** SoA obrigatório para batches de entidades

### Raylib

- **Versão:** 5.5.0
- **Uso:** Renderização 3D, shaders, audio, input
- **Editores:** RenderTexture2D para viewports off-screen

### Nuklear

- **Uso:** Immediate Mode GUI (ZUI, editores)
- **Estilo:** 90s Winamp / Windows 3.1

### SDL2

- **Uso:** Engine principal (raycasting)
- **Separação:** Engine = SDL2, Editores = Raylib

---

## 📊 Performance Budgets

### Frame (60 FPS)

| System | Budget |
|--------|--------|
| Logic Update | < 4ms |
| Render | < 8ms |
| Audio | < 2ms |
| Input | < 1ms |
| **Total** | **< 16.67ms** |

### Memória

| Allocator | Budget | Reset |
|-----------|--------|-------|
| Frame Arena | 10 MB | Todo frame |
| Persistent GPA | 100 MB | Game lifetime |
| Entity Pool | 5 MB | Level lifetime |

---

## 🛠️ Ferramentas

### Asset Proxy

```bash
# Converter PNG para QOI
./zig-out/bin/asset_proxy assets/source.png assets/output.qoi
```

### Batch Convert

```bash
# Converter todos PNGs
./tools/batch_convert.sh
```

### Gen Metadata

```bash
# Gerar YAML para sprite
python scripts/gen_metadata.py server_rack assets/game/objects/server/object.yaml
```

---

## 📖 Exemplos de Uso

### Exemplo 1: Nova Feature (Lone Wolf)

```markdown
1. Adicionar FEAT-001 em docs/backlog.md
2. Preencher docs/notes/2026-03-31_feat_001_notes.md
   - What: Sistema de grama com shader
   - Why: Melhorar estética do ambiente
   - How: Vertex shader sway + fragment quantize
3. Codar em src/grass_renderer.zig
4. Quick Drift Check (5 min)
   - Fragmentation: ✅ Zero
   - Vibe Check: ✅ Retro
   - Compliance: ✅ DOD
5. Mover FEAT-001 para Done
```

### Exemplo 2: Nova Feature (Corporate)

```markdown
1. Criar RRA-025 em docs/editors/features/grass_shader/RRA-025.md
2. PlantUML: docs/editors/features/grass_shader/architecture.puml
3. Renderizar: plantuml -tpng architecture.puml
4. Stakeholder Commentary (11 personas)
5. Adicionar em docs/architecture/backlog.md (Pending)
6. Sprint Planning: Selecionar RRA-025 para Sprint 4
7. Implementation Report: docs/reports/.../RRA-025_impl.md
8. POC: src/playgrounds/grass_poc.zig
9. Codar sistema final: src/grass_renderer.zig
10. Drift Report: docs/reports/.../drift_report.md
11. Sprint Retro: docs/reports/.../sprint_4_retro.md
12. Mover RRA-025 para Audit Trail
```

### Exemplo 3: POC de Sistema Complexo

```markdown
1. RRA-030: Map Editor
2. Macro POC: src/playgrounds/map_forge_poc.zig
3. Docs: docs/editors/features/map_forge/poc/
   - setup.md
   - findings.md
   - validation.md
4. Validação: 5 dias
5. Stakeholder Review
6. Decision: ✅ INTEGRATE
7. Integration Plan:
   - Move para src/map_forge.zig
   - Refatorar para DOD
   - Drift Report
   - Tech Debt logged
```

---

## 🔗 Referências Cruzadas

```
workflow_orchestrator (Skill Mestra)
    │
    ├─→ tech_stack_zig_raylib (Implementação)
    │       └─→ game_mechanics_dod (Mecânicas)
    │       └─→ asset_pipeline_qoi (Assets)
    │
    ├─→ style_guide_retro_fps (Estética)
    │       └─→ editor_ui_standards (UI de Editores)
    │
    └─→ poc_factory (Validação)
            └─→ Todas as features novas
```

---

## 📝 Checklist de Setup

### Setup Básico

- [ ] Copiar skills para `.qwen/skills/`
- [ ] Escolher workflow (Corporate ou Lone Wolf)
- [ ] Criar estrutura de diretórios
- [ ] Configurar build.zig
- [ ] Setup inicial de assets

### Setup Corporate

- [ ] Criar `docs/architecture/backlog.md`
- [ ] Criar `docs/architecture/technical_debt.md`
- [ ] Copiar templates para `docs/templates/`
- [ ] Configurar PlantUML local
- [ ] Definir personas de stakeholders

### Setup Lone Wolf

- [ ] Criar `docs/backlog.md`
- [ ] Criar `docs/tech_debt.md`
- [ ] Copiar templates Lone Wolf
- [ ] Definir princípios (opcional)
- [ ] Começar a codar!

---

## 🎓 Aprendizados do Projeto Original

### O Que Funcionou

1. **Sátira Corporativa** - Torna documentação burocrática engajante
2. **Drift Analysis** - Pega problemas arquiteturais cedo
3. **POC Playground** - Evita integração prematura
4. **DOD Rigoroso** - Performance consistente
5. **Vibe Curator** - Mantém estética coerente

### O Que Adaptar

1. **Stakeholders** - Reduza de 11 para 3-5 se necessário
2. **Templates** - Simplifique para projetos menores
3. **Drift Reports** - Faça quick checks (5 min) em vez de relatórios completos
4. **RRA** - Use apenas para features grandes

---

## 📄 Licença

**MIT License** - Use em qualquer projeto, comercial ou pessoal.

Atribuição não é requerida, mas apreciada!

---

## 🙏 Créditos

Exportado e refinado a partir de:
- **The Last Coffee Break at D.O.O.M.** - Projeto original
- **Skills Originais:** corporate_workflow_registry, rigorous_zig_dod, doom_vibe_curator, etc.

**Versão deste Export:** 1.0  
**Data:** 2026-03-31  
**Exported By:** Qwen (antigo Antigravity)
