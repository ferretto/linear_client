#!/usr/bin/env ruby
require_relative "../lib/linear_client"
require "json"

client = LinearClient::Client.new
viewer = client.viewer
issues = client.my_issues

output = { viewer: viewer, issues: issues }
path = ARGV.first || "/tmp/linear_report_data.json"
File.write(path, JSON.pretty_generate(output))
puts "Dados salvos em #{path} (#{issues.size} issues)"
