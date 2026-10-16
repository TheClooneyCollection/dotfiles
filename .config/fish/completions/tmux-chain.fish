# Only offer a positional directory before one has been supplied.
function __fish_tmux_chain_needs_directory
    set -l needs_value 0
    set -l positional_only 0
    set -l words (commandline -opc)
    for word in $words[2..-1]
        if test $needs_value -eq 1
            set needs_value 0
        else if test $positional_only -eq 1
            return 1
        else
            switch $word
                case --target --name
                    set needs_value 1
                case --
                    set positional_only 1
                case '-*'
                    continue
                case '*'
                    return 1
            end
        end
    end
    test $needs_value -eq 0
end

complete -c tmux-chain -f
complete -c tmux-chain -n __fish_tmux_chain_needs_directory -a '(__fish_complete_directories)'
complete -c tmux-chain -l include-worktrees -d 'Include Git worktrees in the project scan'
complete -c tmux-chain -l no-save -d 'Do not save the launched directory'
complete -c tmux-chain -l save -d 'Save by default (compatibility option)'
complete -c tmux-chain -l target -x -d 'Destination session, optionally with a window index'
complete -c tmux-chain -l name -x -d 'Window name (default: directory basename)'
complete -c tmux-chain -s h -l help -d 'Show help'
