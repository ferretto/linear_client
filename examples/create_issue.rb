#!/usr/bin/env ruby
require_relative "../lib/linear_client"

client = LinearClient::Client.new

teams = client.teams
puts "Times disponiveis:"
teams.each { |t| puts "  #{t['key']} (#{t['name']}) -> id: #{t['id']}" }

team_key = ARGV.first || teams.first.fetch("key")
team = teams.find { |t| t.fetch("key") == team_key }
raise "Time '#{team_key}' nao encontrado" unless team

team_id = team.fetch("id")

result = client.create_issue(
  team_id: team_id,
  title: "Card de teste criado via Ruby",
  description: "Criado pelo script examples/create_issue.rb"
)
issue = result.fetch("issue")
puts "Issue criada: #{issue['identifier']} - #{issue['url']}"

client.create_comment(issue_id: issue.fetch("id"), body: "Primeiro comentario via API.")
puts "Comentario adicionado."
