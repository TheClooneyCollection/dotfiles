complete -c tmux-main-sequence -f
complete -c tmux-main-sequence -n '__fish_use_subcommand' -l add-missing -d 'Add missing project windows before joining'
complete -c tmux-main-sequence -n '__fish_use_subcommand' -l no-attach -d 'Create or update windows without joining'
complete -c tmux-main-sequence -s h -l help -d 'Show help'
complete -c tmux-main-sequence -n '__fish_use_subcommand' -a list -d 'List configured projects'
complete -c tmux-main-sequence -n '__fish_use_subcommand' -a add -d 'Add a project'
complete -c tmux-main-sequence -n '__fish_use_subcommand' -a set -d 'Set a project resume ID'
complete -c tmux-main-sequence -n '__fish_use_subcommand' -a unset -d 'Clear a project resume ID'
complete -c tmux-main-sequence -n '__fish_seen_subcommand_from add' -l at -x -d 'Insert before project N (1-based)'
complete -c tmux-main-sequence -n '__fish_seen_subcommand_from add' -a '(__fish_complete_directories) name= shell resume='
complete -c tmux-main-sequence -n '__fish_seen_subcommand_from set' -a resume=
complete -c tmux-main-sequence -n '__fish_seen_subcommand_from unset' -a resume
