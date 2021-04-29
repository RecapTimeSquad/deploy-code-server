# Start from the code-server Debian base image
FROM codercom/code-server:latest

USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install unzip + rclone (support for remote filesystem)
RUN sudo apt-get update && sudo apt-get install unzip jq -y
RUN curl https://rclone.org/install.sh | sudo bash

# after doing some snapd setup, ensure it switched to the user 'coder'
# and it's working directory is on $HOME
USER coder
WORKDIR /home/coder

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local

# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN sudo apt-get install --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

# You can add custom software and dependencies for your environment below
# -----------

# If installing extensions, please search in Open VSIX website due to legal reasons. Blame Microsoft for this.
# See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
RUN code-server --install-extension esbenp.prettier-vscode

# Install Node.js 14.x
RUN sudo curl -fsSL https://deb.nodesource.com/setup_14.x | sudo bash -
RUN sudo apt-get install -y nodejs
# Don't forget to update npm and install Yarn
RUN sudo npm install -g npm

# Ensure Go and Pyenv paths are there
ENV PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:/usr/local/go/bin:$PATH

# Download Golang
RUN wget https://golang.org/dl/go1.16.3.linux-amd64.tar.gz \
    && sudo tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz \
    && rm -rfv go*.tar.gz

# Install Python 3.x
RUN curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && { echo; \
        echo 'eval "$(pyenv init -)"'; \
        echo 'eval "$(pyenv virtualenv-init -)"'; } >> /home/gitpod/.bashrc.d/60-python \
    && pyenv update \
    && pyenv install 3.8.9 \
    && pyenv global 3.8.9 \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine \
    && sudo rm -rf /tmp/*

# install Cloudflared
RUN wget -q https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb \
    && sudo dpkg -i cloudflared-stable-linux-amd64.deb \
    && rm cloduflared-stable-linux.amd64.deb

# -----------

# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
