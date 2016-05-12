#!/usr/bin/env python2
# Remove all merged branches, except ignored as specified in IGNORE_BRANCHES

# Usage:
#   $ path/to/remove-merged-branches.py # removes all merged branches in default_branch (`master` by default, you can specify it)
#   $ path/to/remove-merged-branches.py develop # specifies `develop` as the default_branch

# How it works?
#
# Checks out the `default_branch`
# Run command `git branch --merged` to find branches merged into `default_branch`
# Exclude branches defined in IGNORE_BRANCHES from the branches in last step
# Delete branches with `git branch -d`

import sys
import subprocess

IGNORE_BRANCHES = ['master', 'develop']

def main():
    if len(sys.argv) > 1:
        default_branch = sys.argv[1]
    else:
        default_branch = 'master'

    IGNORE_BRANCHES.append(default_branch)

    checkout_branch(default_branch)
    merged_branches_except_ignored = filter_branches_with_ignores(
            merged_branches(),
            IGNORE_BRANCHES
            )
    map(delete_branch, merged_branches_except_ignored)

def checkout_branch(branch):
    subprocess.call(['git', 'checkout', branch])

def merged_branches():
    merged_branches = subprocess.check_output(['git', 'branch', '--merged']).splitlines()
    return [ branch.strip() for branch in merged_branches ]

def filter_branches_with_ignores(branches, ignores):
    return [ branch for branch in branches
            if not any( # if the branch does not contain any part of ignored branches
                map(lambda ignore: ignore in branch, ignores)
                )
            ]

def delete_branch(branch):
    try:
        output = subprocess.check_output(['git', 'branch', '-d', branch])
    except subprocess.CalledProcessError as e:
        print("returned non-zero exit status {}".format(e.returncode))

    print(output)

main()
