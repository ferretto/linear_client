# frozen_string_literal: true

RSpec.describe LinearClient::Client do
  let(:api_key) { "test-api-key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:endpoint) { described_class::ENDPOINT }

  def stub_graphql(status: 200, **response_body)
    stub_request(:post, endpoint)
      .with(headers: { "Authorization" => api_key, "Content-Type" => "application/json" })
      .to_return(status: status, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#initialize" do
    it "uses the given api_key" do
      expect { described_class.new(api_key: "explicit-key") }.not_to raise_error
    end

    it "falls back to LINEAR_API_KEY when no api_key is given" do
      ENV["LINEAR_API_KEY"] = "from-env"
      stub_request(:post, endpoint)
        .with(headers: { "Authorization" => "from-env" })
        .to_return(
          status: 200,
          body: { data: { teams: { nodes: [] } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { described_class.new.teams }.not_to raise_error
    ensure
      ENV.delete("LINEAR_API_KEY")
    end

    it "raises ArgumentError when no api_key is available" do
      ENV.delete("LINEAR_API_KEY")
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError, /LINEAR_API_KEY/)
    end

    it "raises ArgumentError when api_key is empty" do
      expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, /LINEAR_API_KEY/)
    end
  end

  describe "#teams" do
    it "returns the list of teams" do
      stub_graphql(
        data: { teams: { nodes: [{ id: "team-1", name: "Engineering", key: "ENG" }] } }
      )

      expect(client.teams).to eq(
        [{ "id" => "team-1", "name" => "Engineering", "key" => "ENG" }]
      )
    end
  end

  describe "#viewer" do
    it "returns the authenticated user's name and email" do
      stub_graphql(data: { viewer: { name: "Ada Lovelace", email: "ada@example.com" } })

      expect(client.viewer).to eq({ "name" => "Ada Lovelace", "email" => "ada@example.com" })
    end
  end

  describe "#my_issues" do
    it "returns the issues assigned to the api key owner" do
      issue = {
        id: "issue-1", identifier: "ENG-1", title: "Bug", url: "https://linear.app/x/issue/ENG-1",
        priority: 2, createdAt: "2026-01-01T00:00:00.000Z", updatedAt: "2026-01-02T00:00:00.000Z",
        completedAt: nil, state: { name: "Waiting", type: "started" }, team: { key: "ENG" }
      }
      stub_graphql(data: { viewer: { assignedIssues: { nodes: [issue] } } })

      result = client.my_issues

      expect(result.size).to eq(1)
      expect(result.first).to include("identifier" => "ENG-1", "title" => "Bug")
    end
  end

  describe "#create_issue" do
    it "sends the team_id, title and description and returns the created issue" do
      request = stub_request(:post, endpoint)
        .with do |req|
          body = JSON.parse(req.body)
          body["variables"] == {
            "input" => { "teamId" => "team-1", "title" => "Bug no login", "description" => "Detalhes" }
          }
        end
        .to_return(
          status: 200,
          body: {
            data: {
              issueCreate: {
                success: true,
                issue: { id: "issue-1", identifier: "ENG-2", title: "Bug no login", url: "https://linear.app/x/issue/ENG-2" }
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.create_issue(team_id: "team-1", title: "Bug no login", description: "Detalhes")

      expect(request).to have_been_requested
      expect(result["success"]).to be(true)
      expect(result.dig("issue", "identifier")).to eq("ENG-2")
    end
  end

  describe "#create_comment" do
    it "sends the issue_id and body and returns the created comment" do
      request = stub_request(:post, endpoint)
        .with do |req|
          JSON.parse(req.body)["variables"] == { "input" => { "issueId" => "issue-1", "body" => "Investigando." } }
        end
        .to_return(
          status: 200,
          body: {
            data: { commentCreate: { success: true, comment: { id: "comment-1", url: "https://linear.app/x/issue/ENG-2#comment-1" } } }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.create_comment(issue_id: "issue-1", body: "Investigando.")

      expect(request).to have_been_requested
      expect(result.dig("comment", "id")).to eq("comment-1")
    end
  end

  describe "error handling" do
    it "raises LinearClient::Client::Error when the API returns GraphQL errors" do
      stub_graphql(errors: [{ message: "Authentication required" }])

      expect { client.teams }.to raise_error(described_class::Error, /Authentication required/)
    end
  end
end
