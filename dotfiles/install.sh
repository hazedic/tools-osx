#!/usr/bin/env bash

SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)

install_dotfiles() {
    echo "Installing dotfiles..."
    pushd $SCRIPT_PATH

    DOTFILES=(ipython tmux/tmux.conf vim vimrc)
    for DOTFILE in "${DOTFILES[@]}"; do
        DOTFILE_NAME="$(basename $DOTFILE)"
        DOTFILE_SOURCE="$PWD/$DOTFILE"
        DOTFILE_TARGET="$HOME/.$DOTFILE_NAME"

        [[ -f $DOTFILE_TARGET ]] && rm -rf $DOTFILE_TARGET

        echo "Copying $DOTFILE_SOURCE to $DOTFILE_TARGET"
        cp -rf $DOTFILE_SOURCE $DOTFILE_TARGET
    done

    popd
}

install_ohmyzsh() {
    if [[ $(basename $SHELL) == "zsh" ]]; then
        echo "Zsh is already the default shell. Restart your session to load the new settings."
    else
        command -v zsh &>/dev/null || brew install zsh
        echo "Setting Zsh as the default shell."
        ZSH_PATH=$(which zsh)
        [[ -z $(grep "$ZSH_PATH" /private/etc/shells) ]] && sudo bash -c "echo $ZSH_PATH >> /private/etc/shells"
        chsh -s $ZSH_PATH
    fi

    command -v curl &>/dev/null || brew install curl
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo "Installing oh-my-zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    sed -i '' 's/^plugins=(/&zsh-autosuggestions zsh-syntax-highlighting /' $HOME/.zshrc

    cat >> ~/.zshrc << 'EOF'
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^b' backward-word
bindkey '^f' forward-word
EOF
}

install_pyenv() {
    command -v pyenv &>/dev/null || {
        brew install pyenv
        eval "$(pyenv init -)"
        git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
        eval "$(pyenv virtualenv-init -)"

        cat >> ~/.zshrc << 'EOF'
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
  export BASE_PROMPT=\$PS1
  function updatePrompt {
      [[ \$VIRTUAL_ENV != "" ]] && PS1="(\${VIRTUAL_ENV##*/}) \$BASE_PROMPT" || PS1=\$BASE_PROMPT
  }
  export PROMPT_COMMAND="updatePrompt"
  precmd() { eval "\$PROMPT_COMMAND" }
  alias brew='env PATH="\${PATH//$(pyenv root)\/shims:/}" brew'
fi
EOF
    }

    brew install zlib readline openssl
    PYTHON_VERSION="3.9.13"
    [[ ! -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]] && {
        CPPFLAGS="-I$(brew --prefix zlib)/include -I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -I$(xcrun --show-sdk-path)/usr/include" \
        LDFLAGS="-L$(brew --prefix zlib)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix openssl)/lib" \
        PYTHON_CONFIGURE_OPTS="--enable-shared" \
        pyenv install $PYTHON_VERSION
        pyenv global $PYTHON_VERSION
    }

    cat >> ~/.zshrc << 'EOF'
export CPPFLAGS="-I$(brew --prefix zlib)/include -I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -I$(xcrun --show-sdk-path)/usr/include"
export LDFLAGS="-L$(brew --prefix zlib)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix openssl)/lib"
export PYTHON_CONFIGURE_OPTS="--enable-shared"
EOF
}

install_ipython() {
    command -v ipython &>/dev/null || pip install 'ipython[zmq,qtconsole,notebook,test]'
}

install_js() {
    brew list node &>/dev/null || {
        brew install node
        npm install -g yarn
    }
}

install_golang() {
    brew list go &>/dev/null || {
        brew install golang
        mkdir -p $HOME/go/{bin,src,pkg}
        cat >> ~/.zshrc << 'EOF'
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/opt/homebrew/bin:$GOBIN
EOF
    }
}

install_sdkman() {
    command -v curl &>/dev/null || brew install curl
    command -v sdk &>/dev/null || {
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    }
}

install_jenv() {
    command -v jenv &>/dev/null || {
        brew install jenv
        ZENV_ZSH_PATH="$(brew --cellar jenv)/$(brew list --versions jenv | tr ' ' '\n' | tail -1)/libexec/libexec/../completions/jenv.zsh"
        cat >> ~/.zshrc <<EOF
export PATH="$HOME/.jenv/shims:\$PATH"
export JENV_SHELL=zsh
export JENV_LOADED=1
unset JAVA_HOME
source $ZENV_ZSH_PATH
jenv rehash 2>/dev/null
jenv refresh-plugins
jenv() {
  typeset command
  command="\$1"
  shift
  case "\$command" in
  enable-plugin|rehash|shell|shell-options)
    eval \`jenv "sh-\$command" "\$@"\`;;
  *)
    command jenv "\$command" "\$@";;
  esac
}
EOF
    }
}

install_vim() {
    brew install lua luajit
    brew list vim &>/dev/null || brew install vim
    brew list neovim &>/dev/null || {
        brew install neovim
        pip install --upgrade pip
        pip install pynvim
        mkdir -p $HOME/.config
        ln -sf $HOME/.vim $HOME/.config/nvim
        ln -sf $HOME/.vimrc $HOME/.config/nvim/init.vim
    }
    brew install cmake ctags cscope global findutils ack
    pip install python-language-server
    vim +'PlugInstall --sync' +qa
    cat >> ~/.zshrc << 'EOF'
alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"
EOF
}

install_tmux() {
    brew list tmux &>/dev/null || {
        brew install tmux
        [[ ! -d "$HOME/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
    }
}

install_kubectl() {
    command -v curl &>/dev/null || brew install curl
    command -v kubectl &>/dev/null || {
        OS=$(uname | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$OS/$ARCH/kubectl"
        sudo mkdir -p /usr/local/bin
        sudo mv kubectl /usr/local/bin
        sudo chmod +x /usr/local/bin/kubectl

        pushd "$(mktemp -d)"
        KREW="krew-${OS}_${ARCH}"
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW.tar.gz"
        tar zxvf "$KREW.tar.gz"
        ./$KREW install krew
        popd

        brew install kubecolor/tap/kubecolor danielfoehrkn/switch/switch
        cat >> ~/.zshrc << 'EOF'
alias k=kubecolor
source <(kubectl completion zsh)
complete -F __start_kubectl k
compdef kubecolor="kubectl"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
INSTALLATION_PATH=$(brew --prefix switch) && source $INSTALLATION_PATH/switch.sh
EOF
    }
}

install_k9s() {
    command -v k9s &>/dev/null || brew install k9s
    mkdir -p "$HOME/Library/Application Support/k9s"
    cp -f $SCRIPT_PATH/k9s/* "$HOME/Library/Application Support/k9s"
}

if ! pkgutil --pkgs | grep -q "com.apple.pkg.Xcode"; then
    echo "Xcode is not installed. Install it from the Apple AppStore."
    exit 1
fi

if ! pkgutil --pkgs | grep -q "com.apple.pkg.CLTools_Executables"; then
    echo "Command Line Tools are not installed. Installing now..."
    sudo xcode-select --install
    while pgrep -q "Install Command Line Developer Tools"; do
        sleep 1
    done
fi

if ! command -v brew &>/dev/null; then
    echo "Homebrew missing. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$($(brew --prefix)/bin/brew shellenv)"
else
    echo "Homebrew is already installed."
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
