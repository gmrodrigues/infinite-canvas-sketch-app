# Macro POC: [Feature Name]
**RRA**: RRA-XXX
**Date**: YYYY-MM-DD
**Duration**: 3-5 dias

## 1. Executive Summary
[Visão geral de 2-3 parágrafos da POC e seus objetivos]

## 2. Playground Configuration

**Location**: `src/playgrounds/[feature]_poc.zig`

**Build Command**:
```bash
zig build run-[feature]-poc
```

**Dependencies**:
- [Dep 1]
- [Dep 2]

**Assets Required**:
- [Asset 1]
- [Asset 2]

## 3. Objectives

### Primary (Must Validate)
- [ ] [Objective 1]
- [ ] [Objective 2]

### Secondary (Nice to Validate)
- [ ] [Objective 1]
- [ ] [Objective 2]

## 4. Implementation Phases

### Phase 1: Foundation (Day 1-2)
- [ ] [Task 1.1]
- [ ] [Task 1.2]
- [ ] [Task 1.3]

### Phase 2: Validation (Day 3)
- [ ] [Task 2.1]
- [ ] [Task 2.2]

### Phase 3: Edge Cases (Day 4)
- [ ] [Task 3.1]
- [ ] [Task 3.2]

### Phase 4: Documentation (Day 5)
- [ ] [Task 4.1]
- [ ] [Task 4.2]

## 5. Findings

### Technical
- [Finding 1]
- [Finding 2]

### Performance
| Metric | Target | Actual | Pass? |
|--------|--------|--------|-------|
| FPS | 60 | [X] | ✅/❌ |
| Memory | < X MB | [Y] MB | ✅/❌ |
| Frame Time | < 16ms | [X]ms | ✅/❌ |

### Vibe/Aesthetic
- [Finding 1]
- [Finding 2]

## 6. Edge Cases

| Case | Description | Handling | Status |
|------|-------------|----------|--------|
| 1 | [Descrição] | [Como lidado] | ✅/❌ |
| 2 | [Descrição] | [Como lidado] | ✅/❌ |

## 7. Validation Results

| Objective | Status | Notes |
|-----------|--------|-------|
| Obj 1 | ✅ / ❌ | [Notes] |
| Obj 2 | ✅ / ❌ | [Notes] |
| Obj 3 | ✅ / ❌ | [Notes] |

## 8. Integration Plan

### Code Migration
- [ ] Move de playground para src/
- [ ] Refatorar para DOD/SoA
- [ ] Separar em systems
- [ ] Adicionar tests

### Documentation
- [ ] Atualizar spec.md
- [ ] Atualizar backlog.md
- [ ] Gerar drift report

### Asset Pipeline
- [ ] Assets finais (QOI, etc.)
- [ ] Metadados YAML
- [ ] Integração com asset manager

### Debt
- [ ] Log new TD/PD

## 9. Stakeholder Review

**The Architect**: "[Opinião técnica]"

**The Vibe Curator**: "[Avaliação estética]"

**The Retro Purist**: "[Opinião sobre performance]"

**The Junior Dev**: "[Feedback de usabilidade]"

## 10. Decision

- [ ] ✅ INTEGRATE TO MAIN - POC validada, pronto para produção
- [ ] ⚠️ REVISE AND RE-POC - Precisa mais validação
- [ ] ❌ ABANDON - Abordagem não funciona

### If Abandoned: Why?
[Explicação detalhada do porquê não funcionou]

---

**POC Status**: COMPLETE / IN_PROGRESS / ABANDONED  
**Author**: [Name]  
**Review Date**: YYYY-MM-DD
