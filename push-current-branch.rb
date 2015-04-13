#!/usr/bin/env ruby

def main
  push_branch current_branch
end

def push_branch(branch)
  `git push origin #{branch}`
end

def current_branch
  `git rev-parse --abbrev-ref HEAD`.strip
end

main
