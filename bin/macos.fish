function compile_vim_plugins
    compile_command_t
    compile_YCM
end

function compile_YCM
    pushd ~/.vim/.vim/bundle/YouCompleteMe/
    echo "compiling YCM"
    ./install.py
    echo "Done!"
    popd
end

function compile_command_t
    pushd ~/.vim/.vim/bundle/command-t/ruby/command-t/
    echo "configuring CommandT"
    ruby extconf.rb
    echo "compiling CommandT"
    make
    echo "Done!"
    popd
end

function disable_bouncing_dock_icons
    defaults write com.apple.dock no-bouncing -bool TRUE
    killall Dock
    echo "disabled bouncing icons. 😝"
end
