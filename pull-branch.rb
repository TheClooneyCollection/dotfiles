#!/usr/bin/env ruby

def main(args)
  pull_branch args[0]
end

def pull_branch(branch)
  puts "Pulling #{branch}"
  on_branch = current_branch
  check_out branch
  pull
  check_out on_branch
end

def current_branch
  `git rev-parse --abbrev-ref HEAD`.strip
end

def check_out(branch)
  `git checkout #{branch}`
end

def pull
  `git pull`
end

main $*
