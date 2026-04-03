# Implementation Notes: FEAT-XXX
**Date**: YYYY-MM-DD
**Time Started**: HH:MM

## What
[O que vou implementar em 1-2 frases claras]

## Why
[Por que é necessário/útil - valor da feature]

## How
[Abordagem técnica em bullets]
- [ ] [Step 1: Setup/Prep]
- [ ] [Step 2: Implementation]
- [ ] [Step 3: Integration]
- [ ] [Step 4: Testing]

## Memory Model
- **Allocator**: [Arena / GPA / Pool]
- **Expected allocations**: [N por frame]
- **Deallocation**: [Frame reset / Manual]

## DOD Notes
- **SoA structs**: [Quais structs serão SoA]
- **Cache patterns**: [Sequential access? Random?]
- **System boundaries**: [Onde começa/termina]

## Vibe Check
- [ ] Mantém estética retro?
- [ ] Zero modernisms?
- [ ] Paleta/resolução corretas?
- [ ] UI 90s compliant?

## Dependencies
- [Dependência 1]
- [Dependência 2]

## Risks
- [Risk 1: O que pode dar errado]
- [Risk 2]

## Success Criteria
- [ ] [Critério 1: Feature funciona]
- [ ] [Critério 2: Performance ok]
- [ ] [Critério 3: Zero leaks]
- [ ] [Critério 4: Vibe compliant]

## Build Commands
```bash
# Build
zig build run-[feature]

# Test
zig build test
```

---

**Time Finished**: HH:MM  
**Status**: ✅ DONE / ⚠️ PARTIAL / ❌ BLOCKED
