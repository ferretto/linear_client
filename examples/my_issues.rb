#!/usr/bin/env ruby
require_relative "../lib/linear_client"

client = LinearClient::Client.new
issues = client.my_issues

if issues.empty?
  puts "Nenhuma issue atribuida a voce."
else
  issues.each do |issue|
    puts "#{issue['identifier']} [#{issue['team']['key']} / #{issue['state']['name']}] #{issue['title']} -> #{issue['url']}"
  end
end
