# Quality Engineering System & Workflow Net

> **Document ID:** `ASSESSMENT-02`  
> **Platform:** AI Interview Platform (`api/` + `web/`)  
> **Evaluation Phase:** Step 2 — Build the Net  
> **Author:** Muhammad Nuril Huda Maulani

---

## 1. Overview & Architecture of the Quality System

The quality system built here addresses the core mandate of the SDET role: **hardening the development workflow so that defects and incomplete work cannot move forward unnoticed**, while deploying a sharp, automated test net that catches data integrity and cross-service seam failures.

The system consists of two complementary halves:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ENGINEERING QUALITY SYSTEM                            │
├──────────────────────────────────────┬──────────────────────────────────────┤
│      1. WORKFLOW HARDENING (GATE)    │     2. AUTOMATED QUALITY NET (CI)    │
│  Definition of Ready (G2 Buildable)  │  Critical Path & Regression Checks   │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • PR Template (.github/pull_request) │ • RSpec Suite (api/spec/)            │
│ • Input Validator (validate-pr.js)   │ • Contract Suite (web/src/__tests__/)│
│ • G2 CI Gate (workflow-gate.yml)     │ • Unified CI Pipeline (ci.yml)       │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 2. Part 1: The Workflow Gate (Hardening the Process)

### Problem Addressed
In production squad delivery, features frequently rot from "ghost specs"—changes moving forward without PRDs, missing acceptance criteria, or code changes shipped without automated tests. 

### Implementation:
1. **Definition of Ready (DoR) Checklist (`.github/pull_request_template.md`)**:
   Mandates that every PR carries:
   * **Linked Spec / PRD reference** (e.g., `PRD-01 Section 2`, issue tracking number).
   * **Acceptance Criteria** in verifiable Given/When/Then or concrete test scenarios.
   * **Solution & Design Plan** explaining the architectural approach.
   * **Quality Net & Test Evidence** declaring tests added and failure modes guarded.

2. **Automated Gate Engine (`.github/scripts/validate-pr.js`)**:
   A deterministic validation engine that runs on pull request events:
   * **Rejects** PRs with default, empty, or placeholder descriptions.
   * **Enforces** that any code modification in `api/app/` or `web/src/` **must** be accompanied by test additions or modifications in `spec/` or `__tests__/`.
   * **Blocks** changes silently slipping through without explicit acceptance criteria.

3. **CI Gate Workflow (`.github/workflows/workflow-gate.yml`)**:
   Runs automatically on all PR events (`opened`, `edited`, `synchronize`). A PR missing inputs **fails with exit code 1**, producing a clear blocking notice on GitHub.

### How a Developer Resolves a Rejection
When the Workflow Gate blocks a Pull Request with `GATE BLOCKED — Missing Definition of Ready Inputs`:
1. **Identify the missing inputs** from the CI log output (e.g. Missing linked Spec/PRD, missing Given/When/Then acceptance criteria, or missing tests for modified code in `api/app` or `web/src`).
2. **Edit the Pull Request description** directly on GitHub (or via GitHub CLI) to populate the required sections according to `.github/pull_request_template.md`:
   - Specify the exact Spec/PRD or tracking reference.
   - Outline the concrete Given/When/Then scenarios.
   - Detail the technical solution plan.
3. **Add automated tests** in `api/spec/` or `web/src/__tests__/` if application code was touched.
4. **Push or save the edit**: The Workflow Gate automatically re-triggers on description edit or push, immediately unblocking the pipeline to proceed to CI test execution.

### Demonstration PRs in Repository
As required by the case study evaluation, two demonstration branches and Pull Requests are retained in this repository:
1. **Blocked Demonstration (`demo/workflow-gate-blocked`)**: PR submitted without linked spec and acceptance criteria — blocked by the Workflow Gate (RED).
2. **Passed Demonstration (`demo/workflow-gate-passed`)**: PR submitted with full Definition of Ready inputs — passed by the Workflow Gate (GREEN).

---

## 3. Part 2: The Automated Quality Net (Targeting Real Defects)

Rather than generating broad, shallow coverage on trivial code, the automated net targets the **risk-carrying paths and data integrity seams** identified in the Audit (Step 1):

### 1. Candidate Invite Routing Integrity (`api/spec/models/session_spec.rb`)
* **What It Protects:** Guards against **P0-01**. Verifies that `Session#invite_url` points exclusively to the candidate-facing Web SPA (port 5173 or `FRONTEND_BASE_URL`), never to the internal Rails API port (3001) where candidates receive a 404 Routing Error.
* **Why It Starts RED:** The current codebase hardcodes `APP_BASE_URL` (defaulting to `http://localhost:3001`), routing candidates to a dead endpoint.

### 2. Human Assessor Override Preservation (`api/spec/services/portfolios/generator_spec.rb`)
* **What It Protects:** Guards against **P0-02 (Data Integrity)**. Ensures that when background portfolio generation/regeneration runs, human assessor review notes and grade overrides (`assessor_overrides`) are **never wiped out**.
* **Why It Starts RED:** `Portfolios::Generator#save_skills` executes `portfolio.portfolio_skills.destroy_all`, which cascades into foreign keys and permanently destroys existing `assessor_overrides`. The test verifies that existing overrides remain intact after regeneration.

### 3. Cross-Service Fit/Gap Data Contract (`api/spec/services/fit_gap/engine_spec.rb`)
* **What It Protects:** Guards against **P1-01** and **P1-02**. Ensures that `FitGap::Engine#call` produces a comparison hash conforming to the frontend TypeScript contract:
  * Includes `required_level` (preventing blank benchmark columns).
  * Includes `is_override: true` when a skill has been human-modified.
* **Why It Starts RED:** The current backend only emits `expected_level` and omits the `is_override` boolean flag.

### 4. Frontend Contract Suite (`web/src/__tests__/contract.test.ts`)
* **What It Protects:** Verifies contract compatibility on the frontend client and flags confusing method naming (e.g. `getOverride` mutating data via POST).

---

## 4. What the Quality Net Protects vs. What It Deliberately Does Not Cover

| Layer / Check | What It Protects | What It Deliberately Does NOT Cover |
| :--- | :--- | :--- |
| **Workflow Gate** | Prevents code without inputs (PRD, acceptance criteria, tests) from ever being merged. | Does not judge subjective literary quality of the PRD prose; ensures the engineering precondition is hard and explicit. |
| **Invite URL Spec** | Guarantees candidate access to the interview UI; prevents 404 routing failures. | Does not mock candidate network bandwidth or webcam hardware compatibility. |
| **Override Preservation Spec** | Guarantees irreversible preservation of human assessor notes and grading overrides across retries. | Does not validate external Gemini LLM response quality or hallucinations (mocked deterministically). |
| **Fit/Gap Contract Spec** | Guarantees frontend/backend synchronization so recruiter dashboards never display blank benchmark tables. | Does not test styling or CSS rendering in headless browsers. |

---

## 5. How to Run the Quality System Locally and in CI

### Running in CI:
Both pipelines execute automatically on GitHub Actions:
* **Workflow Gate:** Runs on every Pull Request via `.github/workflows/workflow-gate.yml`.
* **CI Quality Net:** Runs on pushes to `main` and Pull Requests via `.github/workflows/ci.yml`.

### Running Locally:

#### 1. Test the Workflow Gate Validator:
```bash
# Test with sample input
node .github/scripts/validate-pr.js "### 1. Inputs & Specification\n- Linked Spec: PRD-01\n- Acceptance Criteria: Given X When Y Then Z\n- Solution Plan: Fix invite URL"
```

#### 2. Run the API Quality Net (RSpec):
```bash
cd api
bundle exec rspec
```

#### 3. Run the Web Quality Net (Vitest):
```bash
cd web
npm test
```

---

## 6. Baseline State: Proving the Net Goes "RED" First

As required by the case study brief, **the net must start RED on the unfixed codebase**:

1. **RSpec `Session#invite_url`:**
   * **Status:** ❌ **FAILS (RED)**
   * **Failure:** Expected `http://localhost:3001/interview/...` not to include `:3001`.
2. **RSpec `Portfolios::Generator#call` (Override Preservation):**
   * **Status:** ❌ **FAILS (RED)**
   * **Failure:** Expected 1 assessor override to be preserved, but got 0 (destroyed by `destroy_all` cascade).
3. **RSpec `FitGap::Engine#call` (Contract Alignment):**
   * **Status:** ❌ **FAILS (RED)**
   * **Failure:** Expected comparison hash to include `required_level` and `is_override`.
4. **Vitest `contract.test.ts`:**
   * **Status:** ❌ **FAILS (RED)**
   * **Failure:** Expected API client to export clear save override method instead of `getOverride`.

This establishes the baseline: **the quality net catches the exact defects found in Step 1 before any human looks**. In Step 3, we switched hats to fix the code across the stack and turned every check from **RED to GREEN**.

---

## 7. Step 3: The Red-to-Green Transition (Defect Fixes Record)

As required by the case study evaluation:
> *"Green earned by fixing, never by weakening tests. We will check git diff on your test files: if you changed the test to make it pass, that is an immediate fail. Document every fix: what was broken, what you changed, why that approach, and how you verified it."*

Every test in `api/spec/` and `web/src/__tests__/` remains **100% unaltered**. All fixes were applied purely to production application code across the full stack:

### Fix Summary Matrix

| Defect ID | Severity | File(s) Changed | Root Cause | Engineering Solution | Verification Outcome |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **P0-01** | **P0** | `api/app/models/session.rb` | Hardcoded port `3001` threw 404 Routing Error when candidate clicked invite link. | Routed `invite_url` to `FRONTEND_BASE_URL` (port `5173`) where the candidate SPA interview view lives. | **GREEN** (`session_spec.rb`) |
| **P0-02** | **P0** | `api/app/services/portfolios/generator.rb` | `destroy_all` cascade permanently erased human assessor grades and review notes on regeneration. | Snapshots existing overrides by skill key before recreation, restoring them cleanly to regenerated records. | **GREEN** (`generator_spec.rb`) |
| **P1-01** | **P1** | `api/app/services/fit_gap/engine.rb` | Backend emitted `expected_level`, causing blank benchmark cells in frontend table. | Added `required_level: expected_level` to comparison hash, satisfying TypeScript interface. | **GREEN** (`engine_spec.rb`) |
| **P1-02** | **P1** | `api/app/services/fit_gap/engine.rb` | Missing `is_override: true` flag in report JSON hid pencil icon indicator. | Emitted `is_override: portfolio_skill ? portfolio_skill[:overridden] : false`. | **GREEN** (`engine_spec.rb`) |
| **P1-03** | **P1** | `web/src/pages/vacancies/VacancyEditPage.tsx` | Deleted skills omitted `_destroy: true`, causing "zombie skills" to persist in DB and reload. | Tracked `initialSkills` and appended `{ id, _destroy: true }` for deleted child records. | **GREEN** (Frontend Verified) |
| **P2-02** | **P2** | `web/src/services/portfolios.ts`, `OverridePanel.tsx` | Mutating `POST` endpoint masqueraded under `getOverride` naming. | Exported `saveOverride` as primary mutation method; aliased `getOverride` for backward compatibility. | **GREEN** (`contract.test.ts`) |

### Test Suite Execution Status Post-Fix

1. **Vitest Web Contract Suite (`web`):**
   * **Result:** `✓ src/__tests__/contract.test.ts (2 tests) PASSED`
   * **Status:** 🟢 **GREEN** (2 passed, 0 failed).
2. **TypeScript & Production Build (`web`):**
   * **Result:** `tsc && vite build` completed with 0 errors (`✓ 1842 modules transformed, built in 17.40s`).
3. **RSpec API Suite (`api`):**
   * **Result:** All 3 regression specs (`session_spec`, `generator_spec`, `engine_spec`) pass against the updated models and services.
   * **Status:** 🟢 **GREEN**.

