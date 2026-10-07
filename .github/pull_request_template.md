## Definition of Ready (DoR) — Workflow Gate

Every pull request must carry its inputs before it is ready to build or merge. This gate is automatically enforced by CI.

---

### 1. Inputs & Specification (Mandatory)
- [ ] **Linked Spec / PRD / Issue**: <!-- e.g., PRD-01, PRD-02, Issue #12, or link -->
- [ ] **Acceptance Criteria (Given / When / Then)**:
  <!-- 
  Given: [Initial state / precondition]
  When:  [Action taken]
  Then:  [Expected verifiable outcome]
  -->
- [ ] **Solution / Design Plan**:
  <!-- Brief 2-3 sentence overview of the technical change -->

---

### 2. Quality Net & Test Evidence (Mandatory for Code Changes)
- [ ] **Tests Included**:
  <!-- List new or updated test files in api/spec/ or web/src/__tests__/ -->
- [ ] **Failure Mode Tested**:
  <!-- What specific class of failure does this test protect against? -->
- [ ] **Data Integrity Impact**:
  <!-- Does this touch persisted data, overrides, or cross-service contracts? If yes, explain how integrity is guaranteed. -->

---

### 3. Change Classification
- [ ] Bug fix (P0 / P1 / P2 / P3)
- [ ] Quality gate / workflow hardening
- [ ] Feature / enhancement
- [ ] Documentation / audit
