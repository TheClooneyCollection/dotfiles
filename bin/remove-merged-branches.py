#!/usr/bin/env python2
# Remove all merged branches, except ignored as specified in IGNORE_BRANCHES

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
    print(subprocess.check_output(['git', 'branch', '-d', branch]))

main()
