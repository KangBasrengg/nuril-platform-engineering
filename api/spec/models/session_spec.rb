# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Session, type: :model do
  describe '#invite_url' do
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
        name: 'Senior QA Engineer',
        time_limit_min: 45
      )
    end

    let(:session) do
      Session.create!(
        tenant_id: organization.id,
        assessment: assessment,
        candidate_name: 'Budi Santoso'
      )
    end

    it 'generates a valid invite URL with the invite token' do
      expect(session.invite_url).to include(session.invite_token)
    end

    it 'routes candidates to the frontend web application, never the backend Rails API port' do
      # P0-01 Quality Net Check:
      # The backend Rails API serves on port 3001 and has no GET /interview/:token route.
      # The invite link must direct candidates to the Web SPA (default port 5173 or FRONTEND_BASE_URL).
      expect(session.invite_url).not_to include(':3001')
      expect(session.invite_url).to match(%r{http://localhost:5173/interview/#{session.invite_token}})
    end
  end
end
