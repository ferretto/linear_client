# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module LinearClient
  # Cliente minimo para a API GraphQL do Linear (https://api.linear.app/graphql).
  # Nao ha SDK oficial para Ruby, entao falamos GraphQL diretamente via Net::HTTP.
  class Client
    ENDPOINT = "https://api.linear.app/graphql"

    class Error < StandardError; end

    def initialize(api_key: ENV["LINEAR_API_KEY"])
      raise ArgumentError, "LINEAR_API_KEY nao configurada" if api_key.nil? || api_key.empty?

      @api_key = api_key
    end

    # team_id: id do time no Linear (veja #teams para descobrir)
    def create_issue(team_id:, title:, description: nil)
      query = <<~GRAPHQL
        mutation IssueCreate($input: IssueCreateInput!) {
          issueCreate(input: $input) {
            success
            issue { id identifier title url }
          }
        }
      GRAPHQL

      data = execute(query, input: { teamId: team_id, title: title, description: description })
      data.fetch("issueCreate")
    end

    def create_comment(issue_id:, body:)
      query = <<~GRAPHQL
        mutation CommentCreate($input: CommentCreateInput!) {
          commentCreate(input: $input) {
            success
            comment { id url }
          }
        }
      GRAPHQL

      data = execute(query, input: { issueId: issue_id, body: body })
      data.fetch("commentCreate")
    end

    # Issues atribuidas ao dono da API key
    def my_issues
      query = <<~GRAPHQL
        query MyIssues {
          viewer {
            assignedIssues {
              nodes {
                id
                identifier
                title
                url
                priority
                createdAt
                updatedAt
                completedAt
                state { name type }
                team { key }
              }
            }
          }
        }
      GRAPHQL

      execute(query).dig("viewer", "assignedIssues", "nodes")
    end

    def viewer
      query = <<~GRAPHQL
        query Viewer {
          viewer { name email }
        }
      GRAPHQL

      execute(query).fetch("viewer")
    end

    # Util para descobrir os teamIds disponiveis no workspace
    def teams
      query = <<~GRAPHQL
        query Teams {
          teams { nodes { id name key } }
        }
      GRAPHQL

      execute(query).dig("teams", "nodes")
    end

    private

    def execute(query, **variables)
      uri = URI.parse(ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = @api_key
      request.body = { query: query, variables: variables }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      payload = JSON.parse(response.body)

      raise Error, payload["errors"].to_s if payload["errors"] && !payload["errors"].empty?

      payload.fetch("data")
    end
  end
end
