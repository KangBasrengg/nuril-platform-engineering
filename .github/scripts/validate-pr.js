#!/usr/bin/env node
/**
 * Workflow Gate: Definition of Ready (DoR) Validator
 *
 * Enforces that no Pull Request can proceed or merge without:
 * 1. A linked spec or PRD reference.
 * 2. Explicit Acceptance Criteria (Given/When/Then or test scenarios).
 * 3. A solution/design plan.
 * 4. Test files accompanying any functional code changes in api/ or web/.
 *
 * Exit codes:
 *   0: Passed (DoR inputs complete and verified)
 *   1: Blocked (Missing required inputs)
 */

const fs = require('fs');
const { execSync } = require('child_process');

function getPrContext() {
  const eventPath = process.env.GITHUB_EVENT_PATH;
  if (eventPath && fs.existsSync(eventPath)) {
    const event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));
    if (event.pull_request) {
      return {
        title: event.pull_request.title || '',
        body: event.pull_request.body || '',
        baseRef: event.pull_request.base ? event.pull_request.base.sha : 'HEAD~1',
        headRef: event.pull_request.head ? event.pull_request.head.sha : 'HEAD',
        isPr: true
      };
    }
  }

  // Fallback for local testing or manual CLI execution
  const bodyArg = process.argv[2];
  return {
    title: 'Manual execution',
    body: bodyArg || process.env.PR_BODY || '',
    baseRef: 'HEAD~1',
    headRef: 'HEAD',
    isPr: false
  };
}

function getChangedFiles(baseRef, headRef) {
  try {
    const output = execSync(`git diff --name-only ${baseRef} ${headRef}`, { encoding: 'utf8' });
    return output.split('\n').map(s => s.trim()).filter(Boolean);
  } catch {
    // If git diff fails (e.g. shallow clone or initial commit), try against HEAD^ or HEAD
    try {
      const output = execSync('git diff --name-only HEAD~1 HEAD', { encoding: 'utf8' });
      return output.split('\n').map(s => s.trim()).filter(Boolean);
    } catch {
      return [];
    }
  }
}

function validateDoR() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔍 ENGINEERING WORKFLOW GATE: Definition of Ready Verification');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const { body, baseRef, headRef, isPr } = getPrContext();
  const errors = [];
  const passes = [];

  // 1. Verify PR Body Length
  if (!body || body.trim().length < 40) {
    errors.push('PR description is missing or too short. You must fill out the Definition of Ready template.');
  }

  // 2. Check Linked Spec / PRD
  // Must have text after "Linked Spec" that is not just comments, blanks, or placeholders
  const specMatch = body.match(/Linked Spec[^\n:]*:\s*([^\n\r]+)/i);
  const specValue = specMatch ? specMatch[1].replace(/<!--.*?-->/g, '').trim() : '';

  if (!specValue || specValue.toLowerCase() === 'todo' || specValue.toLowerCase() === 'none') {
    errors.push('Missing linked Spec/PRD. A change cannot proceed without its upstream requirement linked.');
  } else {
    passes.push(`Linked Spec verified: "${specValue}"`);
  }

  // 3. Check Acceptance Criteria
  const hasAcceptanceSection = /Acceptance Criteria/i.test(body);
  const acGivenWhenThen = /(Given|When|Then|Scenario|Criteria)/i.test(body);
  // Check if user left default comment or actually filled it
  const cleanBody = body.replace(/<!--[\s\S]*?-->/g, '');
  const acMatch = cleanBody.match(/Acceptance Criteria[\s\S]*?(?=Solution|\n###|$)/i);
  const acContent = acMatch ? acMatch[0].replace(/Acceptance Criteria[^\n:]*:?/i, '').trim() : '';

  if (!hasAcceptanceSection || !acGivenWhenThen || acContent.length < 15) {
    errors.push('Missing Acceptance Criteria. Must specify Given/When/Then scenarios or concrete test criteria.');
  } else {
    passes.push('Acceptance Criteria verified.');
  }

  // 4. Check Solution / Design Plan
  const hasSolutionSection = /Solution[\s\S]*?Plan/i.test(body);
  const solMatch = cleanBody.match(/Solution[^\n:]*Plan[\s\S]*?(?=Quality|\n###|$)/i);
  const solContent = solMatch ? solMatch[0].replace(/Solution[^\n:]*Plan:?/i, '').trim() : '';

  if (!hasSolutionSection || solContent.length < 10) {
    errors.push('Missing Solution/Design Plan. Outline the technical implementation plan.');
  } else {
    passes.push('Solution/Design Plan verified.');
  }

  // 5. Check Test Requirement for Code Changes
  if (isPr) {
    const changedFiles = getChangedFiles(baseRef, headRef);
    const codeFilesChanged = changedFiles.filter(f => 
      (f.startsWith('api/app/') || f.startsWith('web/src/')) &&
      !f.includes('.test.') && !f.includes('.spec.')
    );
    const testFilesChanged = changedFiles.filter(f => 
      f.startsWith('api/spec/') || f.includes('.test.') || f.includes('.spec.')
    );

    if (codeFilesChanged.length > 0) {
      if (testFilesChanged.length === 0) {
        errors.push(`Code changes detected in [${codeFilesChanged.slice(0, 3).join(', ')}...] without corresponding automated tests. You must include tests.`);
      } else {
        passes.push(`Automated tests present: [${testFilesChanged.join(', ')}]`);
      }
    }
  }

  // Output results
  if (passes.length > 0) {
    console.log('✅ Passed Checks:');
    passes.forEach(p => console.log(`   • ${p}`));
    console.log('');
  }

  if (errors.length > 0) {
    console.error('❌ GATE BLOCKED — Missing Definition of Ready Inputs:');
    errors.forEach(e => console.error(`   ⛔ ${e}`));
    console.error('\nResult: PULL REQUEST REJECTED (G2 Gate Enforcement: No inputs, no build).\n');
    process.exit(1);
  }

  console.log('🎉 GATE PASSED: All Definition of Ready inputs are present and verified.');
  console.log('Status: BUILDABLE (Proceed to CI test execution).\n');
  process.exit(0);
}

validateDoR();
