# Start from the code-server Debian base image
FROM codercom/code-server:latest

USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install unzip + rclone (support for remote filesystem)
RUN sudo apt update && sudo apt install --yes unzip jq \
    && curl https://rclone.org/install.sh | sudo bash

# after doing some snapd setup, ensure it switched to the user 'coder'
# and it's working directory is on $HOME
USER coder
WORKDIR /home/coder

RUN mkdir /home/coder/.bashrc.d -p \
    && { echo; \
        echo "for i in \$(ls \$HOME/.bashrc.d); do source \$i; done"; \
        echo } >> /home/coder/.bashrc
COPY deploy-container/bash_aliases/ /hone/coder/.bashrc.d/

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local

# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN sudo apt install --yes --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# You can add custom software and dependencies for your environment below
# -----------

# If installing extensions, please search in Open VSIX website due to legal reasons. Blame Microsoft for this.
# See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
RUN code-server --install-extension esbenp.prettier-vscode

# hard-code versions using environment variables during build-time
ENV NODE_VERSION=14.16.1 \
    GOLANG_VERSION=1.16.3 \
    PYTHON_VERSION=3.8.9

### Node.js ###
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | PROFILE=/dev/null bash \
    && bash -c ". .nvm/nvm.sh \
        && nvm install $NODE_VERSION \
        && nvm alias default $NODE_VERSION \
        && npm install -g typescript yarn node-gyp"
# above, we are adding the lazy nvm init to .bashrc, because one is executed on interactive shells, the other for non-interactive shells (e.g. plugin-host)
COPY --chown=coder:coder deploy-container/nvm-lazy.sh /home/coder/.nvm/nvm-lazy.sh
ENV PATH=$PATH:/home/gitpod/.nvm/versions/node/v${NODE_VERSION}/bin

### Golang ###
ENV PATH=/usr/local/go/bin:$PATH
RUN wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && sudo tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && rm -rfv go*.tar.gz

### Python ###
ENV PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH
RUN curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && eval "$(/home/coder/.pyenv/bin/pyenv init -)" \
    && eval "$(/home/coder/.pyenv/bin/pyenv virtualenv-init -)" \
    && /home/coder/.pyenv/bin/pyenv update && /home/coder/.pyenv/bin/pyenv install $PYTHON_VERSION \
    && /home/coder/.pyenv/bin/pyenv global $PYTHON_VERSION \
    && /home/coder/.pyenv/shims/python3 -m pip install --no-cache-dir --upgrade pip \
    && /home/coder/.pyenv/shims/python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine

### Rust ###
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.51.0 \
    && .cargo/bin/rustup component add \
        rls \
        rust-analysis \
        rust-src \
    && .cargo/bin/rustup completions bash | sudo tee /etc/bash_completion.d/rustup.bash-completion > /dev/null \
    && .cargo/bin/rustup completions bash cargo | sudo tee /etc/bash_completion.d/rustup.cargo-bash-completion > /dev/null

# install Cloudflared
RUN wget -q https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb \
    && sudo dpkg -i cloudflared-stable-linux-amd64.deb

# -----------

# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
