#!/usr/bin/env bash

SCRIPT_PATH=$( cd "$(dirname "$0")" ; pwd )

install_dotfiles() {
    echo "Installing dotfiles..."

    pushd $SCRIPT_PATH

    DOTFILES=(ipython tmux/tmux.conf vim vimrc)
    for DOTFILE in "${DOTFILES[@]}"; do
        DOTFILE_NAME="$(basename $DOTFILE)"
        DOTFILE_SOURCE="$PWD/$DOTFILE"
        DOTFILE_TARGET="$HOME/.$DOTFILE_NAME"

        if [[ -f $DOTFILE_TARGET ]]; then
            rm -rf $DOTFILE_TARGET
        fi

        echo "cp -f $DOTFILE_SOURCE $DOTFILE_TARGET"
        cp -rf $DOTFILE_SOURCE $DOTFILE_TARGET
    done

    popd
}

install_ohmyzsh() {
    USERSHELL=$(basename $SHELL)
    if [[ "$USERSHELL" == "zsh" ]]; then
        echo "Zsh is already configured as your shell of choice."
        echo "Restart your session to load the new settings."
    else
        if [[ ! -x `which zsh` ]]; then
            brew install zsh
        fi

        echo "Setting Zsh as your default shell."
        if [[ -n $(which zsh | grep "/opt/homebrew/bin/zsh") ]]; then
            if [[ -z $(cat /priviate/etc/shells | grep "/opt/homebrew/bin/zsh") ]]; then
                sudo /bin/bash -c "echo /opt/homebrew/bin/zsh >> /private/etc/shells"
            fi
            chsh -s /opt/homebrew/bin/zsh
        else
            chsh -s /bin/zsh
        fi
    fi

    if [[ ! -x `which curl` ]]; then
        brew install curl
    fi

    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo "Installing oh-my-zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    sed -i '' 's/\(^plugins=([^)]*\)/\1 zsh-autosuggestions zsh-syntax-highlighting/' $HOME/.zshrc

cat >> ~/.zshrc << 'EOF'
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^b' backward-word
bindkey '^f' forward-word

EOF
}

install_pyenv() {
    if [[ -z $(brew list 2>/dev/null | grep "pyenv") ]]; then
        brew install pyenv
        eval "$(pyenv init -)"

        git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
        eval "$(pyenv virtualenv-init -)"

cat >> ~/.zshrc << 'EOF'
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
eval "$(pyenv virtualenv-init -)"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export BASE_PROMPT=$PS1
function updatePrompt {
    if [[ $VIRTUAL_ENV != "" ]]; then
        export PS1="(${VIRTUAL_ENV##*/}) "$BASE_PROMPT
    else
        export PS1=$BASE_PROMPT
    fi
}
export PROMPT_COMMAND="updatePrompt"
precmd() { eval "$PROMPT_COMMAND" }

alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'

EOF
    fi

    brew install zlib
    brew install readline
    brew install openssl

    PYTHON_VERSION="3.9.13"
    if [[ ! -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]]; then
        CPPFLAGS="-I$(brew --prefix zlib)/include -I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -I$(xcrun --show-sdk-path)/usr/include" \
        LDFLAGS="-L$(brew --prefix zlib)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix openssl)/lib" \
        PYTHON_CONFIGURE_OPTS="--enable-shared" \
        pyenv install $PYTHON_VERSION
        pyenv global $PYTHON_VERSION
    fi

cat >> ~/.zshrc << 'EOF'
export CPPFLAGS="-I$(brew --prefix zlib)/include -I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -I$(xcrun --show-sdk-path)/usr/include"
export LDFLAGS="-L$(brew --prefix zlib)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix openssl)/lib"
export PYTHON_CONFIGURE_OPTS="--enable-shared"

EOF
}

install_ipython() {
    if [[ ! -x `which ipython` ]]; then
        pip install 'ipython[zmq,qtconsole,notebook,test]'
    fi
}

install_js() {
    if [[ -z $(brew list 2>/dev/null | grep "node") ]]; then
        brew install node
        npm install -g yarn
    fi
}

install_golang() {
    if [[ -z $(brew list 2>/dev/null | grep "go") ]]; then
        brew install golang
        mkdir -p $HOME/go/{bin,src,pkg}
cat >> ~/.zshrc << 'EOF'
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/opt/homebrew/bin:$GOBIN

EOF
    fi
}

install_sdkman() {
    if [[ ! -x `which curl` ]]; then
        brew install curl
    fi

    if [[ ! -x `which sdk` ]]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
}

install_jenv() {
    if [[ ! -x `which jenv` ]]; then
        brew install jenv

ZENV_ZSH_PATH="$(brew --cellar jenv)/$(brew list --versions jenv | tr ' ' '\n' | tail -1)/libexec/libexec/../completions/jenv.zsh"
cat <<EOF >> ~/.zshrc
eval export PATH="$HOME/.jenv/shims:\$PATH"
export JENV_SHELL=zsh
export JENV_LOADED=1
unset JAVA_HOME
source $ZENV_ZSH_PATH
jenv rehash 2>/dev/null
jenv refresh-plugins
jenv() {
  typeset command
  command="\$1"
  if [ "\$#" -gt 0 ]; then
    shift
  fi

  case "\$command" in
  enable-plugin|rehash|shell|shell-options)
    eval \`jenv "sh-\$command" "\$@"\`;;
  *)
    command jenv "\$command" "\$@";;
  esac
}

EOF
    fi
}

install_vim() {
    brew install lua
    brew install luajit

    if [[ ! -e /opt/homebrew/bin/vim ]]; then
        brew install vim
    fi

    if [[ ! -e /opt/homebrew/bin/nvim ]]; then
        brew install neovim

        pip install --upgrade pip
        pip install pynvim

        if [[ ! -d "$HOME/.config" ]]; then
            mkdir $HOME/.config
        fi
        ln -sf $HOME/.vim $HOME/.config/nvim
        ln -sf $HOME/.vimrc $HOME/.config/nvim/init.vim
    fi

    if [[ -e /opt/homebrew/bin/vim ]] && [[ -e /opt/homebrew/bin/nvim ]]; then
        brew install cmake
        brew unlink ctags
        brew install ctags cscope global findutils ack

        pip install python-language-server

        vim +'PlugInstall --sync' +qa
cat >> ~/.zshrc << 'EOF'
alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"

EOF
    fi

    if [ -z "$(ls -A $HOME/Library/Fonts)" ]; then
        echo "Installing patched fonts for Powerline..."
        cp -f $SCRIPT_PATH/fonts/* $HOME/Library/Fonts
    fi
}

install_tmux() {
    if [[ -z $(brew list 2>/dev/null | grep "tmux") ]]; then
        brew install tmux
        if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
            git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
        fi
    fi
}

install_kubectl() {
    if [[ ! -x `which curl` ]]; then
        brew install curl
    fi

    if [[ ! -x `which kubectl` ]]; then
        OS="$(uname | tr '[:upper:]' '[:lower:]')"
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"

        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/$ARCH/kubectl"
        if [[ ! -d /usr/local/bin ]]; then
            sudo mkdir /usr/local/bin
        fi
        sudo mv kubectl /usr/local/bin
        sudo chmod +x /usr/local/bin/kubectl

        pushd "$(mktemp -d)"
        KREW="krew-${OS}_${ARCH}"
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW.tar.gz"
        tar zxvf "$KREW.tar.gz"
        ./"$KREW" install krew
        popd

        brew install kubecolor/tap/kubecolor
        brew install danielfoehrkn/switch/switch

cat >> ~/.zshrc << 'EOF'
alias k=kubecolor
source <(kubectl completion zsh)
complete -F __start_kubectl k
compdef kubecolor="kubectl"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

INSTALLATION_PATH=$(brew --prefix switch) && source $INSTALLATION_PATH/switch.sh

EOF
    fi
}

install_k9s() {
    if [[ ! -x `which k9s` ]]; then
        brew install k9s
    fi

    sudo mkdir -p "$HOME/Library/Application Support/k9s"
    cp -f $SCRIPT_PATH/k9s/* "$HOME/Library/Application Support/k9s"
}

PKGS=`pkgutil --pkgs`
if [[ -z $(echo "$PKGS" | grep com.apple.pkg.Xcode) ]]; then
    echo "Xcode is not installed on this system. Install from the Apple AppStore."
    exit 1
fi

if [[ -z $(echo "$PKGS" | grep com.apple.pkg.CLTools_Executables) ]]; then
    echo "CLTools is not installed on this system."
    echo "Installing Command Line Developer Tools (expect a GUI popup):"
    sudo xcode-select --install
    sleep 2
    while [[ -n $(pgrep "Install Command Line Developer Tools") ]]; do 
        sleep 1
    done
fi

if [[ -n $(brew --prefix 2>&1 | grep "not found") ]]; then
    echo "Homebrew missing. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed."
fi

install_dotfiles
install_ohmyzsh
install_pyenv
install_ipython
install_js
install_golang
install_sdkman
install_jenv
install_vim
install_tmux
install_kubectl
install_k9s
