#!/usr/bin/env ruby

def main
  set_upstream current_branch
end

def set_upstream(branch)
  upstream = "origin/#{branch}"
  puts "set upstream to #{upstream}"
  `git branch --set-upstream-to #{upstream}`
end

def current_branch
  `git rev-parse --abbrev-ref HEAD`.strip
end

main
