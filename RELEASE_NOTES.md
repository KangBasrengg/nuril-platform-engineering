# 🚀 Release Notes - AI Interview Platform v1.0.0

> **Release Version:** `v1.0.0`  
> **Release Date:** October 8, 2026  
> **Status:** **RELEASABLE (SHIP)**  
> **Target Environments:** Production & Staging  
> **Assessor & Lead Engineer:** Muhammad Nuril Huda Maulani (`KangBasrengg` / `MNuril303`)

---

## 🌟 Overview & Release Highlights

Release `v1.0.0` represents a pivotal stabilization and quality milestone for the **Dual-Service AI Interview Platform**. Prior to this release, the platform suffered from critical end-to-end journey failures, data loss on AI regeneration, and contract drifts between the Ruby on Rails backend API and the React Vite frontend SPA.

With `v1.0.0`, all **P0 Critical Blockers** and primary **P1 Major Defects** have been resolved across both services. A permanent, automated **Quality Net CI Pipeline** and a **Definition of Ready (DoR) Workflow Gate** now guard the repository against regressions.

---

## 🛠️ Resolved Defects & Engineering Enhancements

### 1. Critical Journey & Candidate Access (P0-01)
* **Issue:** Candidates clicking invitation links received a Rails `404 Not Found (Routing Error)` because `invite_url` was hardcoded to backend port `3001`, where no frontend interview routes existed.
* **Fix:** Updated `Session#invite_url` in `api/app/models/session.rb` to dynamically target `FRONTEND_BASE_URL` (defaulting to port `5173`), routing candidates directly to the React interview application.

### 2. Human Review Data Integrity (P0-02)
* **Issue:** Triggering portfolio regeneration called `portfolio.portfolio_skills.destroy_all`, triggering foreign-key cascading deletes that permanently wiped out assessor grades (`override_level`) and audit feedback (`assessor_notes`).
* **Fix:** Implemented an in-transaction **Snapshot & Restore** pattern in `api/app/services/portfolios/generator.rb`. Existing assessor overrides are keyed and preserved prior to recreation, then automatically re-attached to the newly generated skill taxonomy.

### 3. Automated Quality Net & Workflow Enforcement (P0-03)
* **Issue:** Codebase had zero automated test coverage and zero CI pipelines.
* **Fix:**
  * Added `.github/workflows/workflow-gate.yml` and `.github/scripts/validate-pr.js` enforcing Definition of Ready on all pull requests.
  * Added `.github/workflows/ci.yml` running containerized PostgreSQL 14 and Redis for RSpec (Ruby 3.3.2) and Vitest + TypeScript compilation (Node 20).
  * Implemented focused contract and regression test suites (`api/spec/` and `web/src/__tests__/`).

### 4. Fit/Gap Dashboard Contract Alignment (P1-01 & P1-02)
* **Issue:** The recruiter dashboard rendered blank benchmark cells (`—`) due to backend emitting `expected_level` while frontend typed `required_level`. Furthermore, the pencil icon indicator (`✏`) for manual assessor overrides never appeared.
* **Fix:** Updated `FitGap::Engine` in `api/app/services/fit_gap/engine.rb` to emit `required_level: expected_level` and explicit `is_override: true/false`, fulfilling the frontend TypeScript contract.

### 5. Vacancy Skill Persistence & "Zombie Skill" Elimination (P1-03)
* **Issue:** Removing skills on the vacancy edit form only sliced local state; saving sent an incomplete array without `_destroy: true`, causing deleted skills to persist in PostgreSQL and reappear upon reload.
* **Fix:** Implemented dirty state tracking (`initialSkills`) in `web/src/pages/vacancies/VacancyEditPage.tsx` that explicitly tracks deleted child record IDs and submits `{ id, _destroy: true }` per Rails `accepts_nested_attributes_for` protocol.

### 6. Semantic API Client Standardization (P2-02)
* **Issue:** The frontend API client used `portfoliosApi.getOverride` to issue state-mutating HTTP `POST` requests.
* **Fix:** Renamed to `saveOverride` in `web/src/services/portfolios.ts` and `OverridePanel.tsx`, maintaining `getOverride` as a backward-compatible alias.

### 7. Engine & Framework Compatibility Fixes
* Configured `WebSocket` acronym inflection in `ActiveSupport::Inflector` to resolve Zeitwerk eager loading constant errors during CI initialization.
* Refactored RSpec database isolation to leverage native Rails transactional fixtures (`use_transactional_fixtures = true`).

---

## 🔒 Verification & Quality Metrics

| Verification Gate | Target Suite | Status | Execution Metrics |
| :--- | :--- | :---: | :--- |
| **API Quality Net** | RSpec (`session_spec`, `generator_spec`, `engine_spec`) | ✅ **PASSED** | 6 examples, 0 failures (0.23s) |
| **Web Quality Net** | Vitest (`contract.test.ts`) | ✅ **PASSED** | 2 tests passed (637ms) |
| **Frontend Production Build** | TypeScript Compiler (`tsc`) & Vite | ✅ **PASSED** | 0 errors, 1842 modules transformed |
| **Database Migrations** | PostgreSQL Schema (`db:migrate:status`) | ✅ **PASSED** | All 4 migrations up |
| **Workflow Gate (DoR)** | PR Template & Metadata Validation | ✅ **PASSED** | Verified via PR #1 (Block) & PR #2 (Pass) |
| **Test Suite Integrity** | Zero Weakening Audit | ✅ **PASSED** | 0 test assertions modified or weakened |

---

## ⚠️ Configuration & Environment Updates

### New Environment Variables
* **`FRONTEND_BASE_URL`** *(Optional, Recommended)*:  
  Specifies the public URL of the React web application (e.g., `https://interview.rakamin.com`). Defaults to `http://localhost:5173` if unset.

### Verified Existing Variables
* `APP_BASE_URL`: Rails API origin (e.g., `http://localhost:3001`).
* `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`: PostgreSQL connection settings.
* `REDIS_URL`: Redis pub/sub and Sidekiq connection string.
* `GEMINI_API_KEY`: Google Gemini API key.
* `GEMINI_FLASH_MODEL`: Defaults to `gemini-2.0-flash-001`.
* `GEMINI_PRO_MODEL`: Defaults to `gemini-2.0-pro-001`.

---

## 📋 Known Limitations & Deferred Work (Risk Acceptance)

The following non-blocking defects identified during Audit `ASSESSMENT-01` are intentionally deferred to `v1.1.0` under documented risk acceptance:

1. **[P1-04] Assessment Edit Language Selector:**  
   * *Status:* Deferred.
   * *Mitigation:* Assessment language is locked upon initial creation and defaults safely to English (`en`) if untouched. Reconfiguration is achievable via API or recreating the assessment template.
2. **[P1-05] Orphaned Public Signup Page:**  
   * *Status:* Deferred.
   * *Mitigation:* The platform operates as an invitation-only B2B application where recruiters and candidates access the system via invited tokens. The `/signup` route is not linked in navigation and presents no operational exposure.
3. **[P2-01] README Variable Name Discrepancy:**  
   * *Status:* Documented in operational runbooks; production configs use `GEMINI_FLASH_MODEL`.

---

## 📦 Deployment & Rollback Instructions

### Deployment Sequence
1. Deploy PostgreSQL schema migrations:
   ```bash
   cd api && bundle exec rails db:migrate
   ```
2. Deploy backend service (`api/`) and start Puma / Sidekiq.
3. Build and deploy frontend static assets (`web/`):
   ```bash
   cd web && npm run build
   ```
4. Verify health checks at `GET /api/v1/health` and verify frontend bundle load.

### Rollback Strategy
* If critical regressions occur, revert to previous deployment container image.
* Database changes in `v1.0.0` are non-breaking additive columns and safe for rollback without immediate schema down-migration.
