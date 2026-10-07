# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FitGap::Engine do
  describe '#call' do
    let(:organization) do
      Organization.create!(
        name: 'Test Corp',
        scheme: 'test-corp',
        identifier: 'test-corp',
        host: 'localhost'
      )
    end

    let(:vacancy) do
      Vacancy.create!(
        tenant_id: organization.id,
        created_by: 1,
        role_title: 'Lead QA Engineer'
      ).tap do |v|
        v.vacancy_skills.create!(
          skill_id: 'sk-ts',
          skill_label: 'TypeScript Core',
          expected_level: 4
        )
      end
    end

    let(:assessment) do
      Assessment.create!(
        tenant_id: organization.id,
        created_by: 1,
        name: 'Lead QA Interview',
        time_limit_min: 45
      )
    end

    let(:session) do
      Session.create!(
        tenant_id: organization.id,
        assessment: assessment,
        status: 'ended'
      )
    end

    let(:portfolio) do
      Portfolio.create!(
        session: session,
        generation_status: 'complete',
        generated_at: Time.current
      )
    end

    let!(:portfolio_skill) do
      portfolio.portfolio_skills.create!(
        skill_id: 'sk-ts',
        skill_label: 'TypeScript Core',
        ai_level: 3,
        ai_confidence: 'high',
        evidence: ['Type gymnastics examples'],
        competency_summary: 'Proficient developer.'
      )
    end

    let(:mock_gemini_client) do
      instance_double(Gemini::HttpClient).tap do |client|
        allow(client).to receive(:generate_content).and_return(
          {
            'culture_narrative' => 'Strong team culture alignment.',
            'overall_narrative' => 'Recommended for technical review.'
          }.to_json
        )
      end
    end

    it 'generates a fit/gap report record' do
      engine = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: mock_gemini_client)
      report = engine.call

      expect(report).to be_persisted
      expect(report.skill_comparisons).to be_an(Array)
    end

    it 'adheres to the web frontend contract: emits required_level and is_override (P1-01 & P1-02 Net)' do
      # Assessor applies an override
      portfolio_skill.create_assessor_override!(
        ai_level: 3,
        override_level: 4,
        assessor_notes: 'Demonstrated advanced generic types in interview.',
        overridden_by: 1,
        overridden_at: Time.current
      )

      engine = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: mock_gemini_client)
      report = engine.call

      comparison = report.skill_comparisons.first

      # P1-01 Assertion:
      # Frontend ComparisonTable.tsx and TypeScript SkillComparison type require `required_level`.
      # Emitting only `expected_level` results in empty cells on the recruiter dashboard.
      has_required_level = comparison.key?('required_level') || comparison.key?(:required_level)
      expect(has_required_level).to be(true), "Expected skill comparison to include 'required_level' for frontend contract compatibility, but keys were: #{comparison.keys}"

      # P1-02 Assertion:
      # Frontend expects `is_override: true` to display the pencil icon indicator for human modifications.
      has_is_override = comparison.key?('is_override') || comparison.key?(:is_override)
      expect(has_is_override).to be(true), "Expected skill comparison to include 'is_override' flag, but keys were: #{comparison.keys}"
      override_value = comparison['is_override'] || comparison[:is_override]
      expect(override_value).to be(true)
    end
  end
end
