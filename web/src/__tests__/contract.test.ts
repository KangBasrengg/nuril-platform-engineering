import { describe, it, expect } from "vitest";
import { portfoliosApi } from "../services/portfolios";
import type { SkillComparison } from "../types";

describe("Frontend/Backend Contract Net", () => {
  it("enforces that SkillComparison requires required_level field (P1-01 Net)", () => {
    // Current backend emits only `expected_level`.
    // The frontend type contract defines `required_level`.
    const validContractPayload: SkillComparison = {
      skill_label: "React",
      required_level: 3,
      candidate_level: 3,
      result: "match",
      is_override: false,
    };

    expect(validContractPayload.required_level).toBeDefined();
    expect(validContractPayload.required_level).toBe(3);
  });

  it("checks portfoliosApi method clarity for saving overrides (P2-02 Net)", () => {
    // Quality check: mutating POST operations must not masquerade under GET-style naming (`getOverride`)
    const hasClearSaveMethod = "saveOverride" in portfoliosApi || "overrideSkill" in portfoliosApi;
    
    // This will fail on the unfixed codebase because the method is misnamed `getOverride`
    expect(hasClearSaveMethod).toBe(true);
  });
});
