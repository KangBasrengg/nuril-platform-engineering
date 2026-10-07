# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Portfolios::Generator do
  describe '#call' do
    let(:organization) do
      Organization.create!(
        name: 'Test Corp',
        scheme: 'test-corp',
        identifier: 'test-corp',
        host: 'localhost'
      )
    end

    let(:assessment) do
      Assessment.create!(
        tenant_id: organization.id,
        created_by: 1,
        name: 'Fullstack Engineer',
        time_limit_min: 45
      )
    end

    let!(:skill_1) do
      assessment.assessment_skills.create!(
        skill_id: 'sk-01',
        skill_label: 'System Design',
        l1_anchor: 'L1', l2_anchor: 'L2', l3_anchor: 'L3', l4_anchor: 'L4', l5_anchor: 'L5',
        expected_level: 3
      )
    end

    let(:session) do
      Session.create!(
        tenant_id: organization.id,
        assessment: assessment,
        status: 'ended',
        started_at: 1.hour.ago,
        ended_at: Time.current
      )
    end

    let(:mock_gemini_client) do
      instance_double(Gemini::HttpClient).tap do |client|
        allow(client).to receive(:generate_content).and_return(
          {
            'configured_skills' => [
              {
                'skill_id' => 'sk-01',
                'skill_label' => 'System Design',
                'level' => 2,
                'confidence' => 'high',
                'evidence' => ['Discussed microservices architecture'],
                'competency_summary' => 'Solid foundational knowledge.'
              }
            ],
            'discovered_skills' => []
          }.to_json
        )
      end
    end

    it 'generates a portfolio with skills successfully' do
      generator = described_class.new(session: session, gemini_client: mock_gemini_client)
      portfolio = generator.call

      expect(portfolio.generation_status).to eq('complete')
      expect(portfolio.portfolio_skills.count).to eq(1)
      expect(portfolio.portfolio_skills.first.skill_label).to eq('System Design')
    end

    it 'preserves human assessor overrides and notes across portfolio regeneration (P0-02 Net)' do
      # Initial generation
      generator = described_class.new(session: session, gemini_client: mock_gemini_client)
      portfolio = generator.call
      target_skill = portfolio.portfolio_skills.find_by(skill_label: 'System Design')

      # Assessor manually overrides the AI rating
      target_skill.create_assessor_override!(
        ai_level: target_skill.ai_level,
        override_level: 4,
        assessor_notes: 'Candidate demonstrated L4 mastery in follow-up discussion.',
        overridden_by: 1,
        overridden_at: Time.current
      )

      expect(portfolio.reload.assessor_overrides.count).to eq(1)

      # Trigger regeneration (e.g. re-running after retry or updated model)
      regenerated_portfolio = described_class.new(session: session, gemini_client: mock_gemini_client).call

      # P0-02 Assertion:
      # Regeneration must NOT silently wipe out human assessor reviews via destroy_all cascade!
      remaining_overrides = regenerated_portfolio.reload.assessor_overrides
      expect(remaining_overrides.count).to eq(1), "Expected 1 assessor override to be preserved, but got 0 (destroyed by destroy_all cascade)"
      expect(remaining_overrides.first.override_level).to eq(4)
      expect(remaining_overrides.first.assessor_notes).to eq('Candidate demonstrated L4 mastery in follow-up discussion.')
    end
  end
end
