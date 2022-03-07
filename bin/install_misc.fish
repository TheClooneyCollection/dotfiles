function clone_spacemacs
    git clone -b develop https://github.com/syl20bnr/spacemacs.git ~/.emacs.d/
end

function install_vagrant
    brew install --cask vagrant virtualbox virtualbox-extension-pack
end

function install_node_packages
    npm install -g js-beautify tern eslint
    # npm install -g jshint
end

function install_chisel
    if test -e ~/.lldbinit
        echo "~/.lldbinit file exists"
    else
        echo "~/.lldbinit file does not exists... Creating one..."
        touch ~/.lldbinit
    end

    grep -Fxq "command script import /usr/local/opt/chisel/libexec/fblldb.py" ~/.lldbinit
    if test $status -eq 0
        echo "Chisel is already instaled"
    else
        echo "command script import /usr/local/opt/chisel/libexec/fblldb.py" >> ~/.lldbinit
        echo "Added chisel to ~/.lldbinit"
    end
end

function install_pelican
    set packages pelican markdown invoke

    pip2 install $packages
    pip3 install $packages

    brew install pandoc
end

function compile_vim_plugins
    compile_command_t
    compile_YCM
end

function compile_YCM
    pushd ~/.vim-plugins/plugins/YouCompleteMe/
    echo "Compiling YCM"
    ./install.py
    echo ""
    echo "Done!"
    echo ""
    popd
end
