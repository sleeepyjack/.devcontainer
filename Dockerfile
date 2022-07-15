
# Use the [Choice] comment to indicate option arguments that should appear in VS Code UX. Use a comma separated list.
#
# [Choice] CUDA version: 11.7.0
ARG VARIANT="11.7.0"
FROM nvcr.io/nvidia/cuda:${VARIANT}-devel-ubuntu22.04

ARG PASSPHRASE
ADD secrets /secrets

ARG DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Berlin

# install packages
RUN apt-get update \
  && apt-get install -y \
  sudo \
  locales \
  locales-all \
  curl \
  wget \
  htop \
  git \
  vim \
  python3 \
  python3-dev \
  python3-pip \
  scons \
  g++ \
  clang-format \
  clang-tidy \
  clang-tools \
  clang \
  clangd \
  libc++-dev \
  libc++1 \
  libc++abi-dev \
  libc++abi1 \
  libclang-dev \
  libclang1 \
  liblldb-dev \
  libllvm-ocaml-dev \
  libomp-dev \
  libomp5 \
  lld \
  lldb \
  llvm-dev \
  llvm-runtime \
  llvm \
  python3-clang \
  cmake \
  cmake-curses-gui \
  git-absorb \
  doxygen \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install \
  lit \
  pre-commit \
  tabulate \
  colorama

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# create container user
ARG USERNAME=djuenger
ARG USER_UID=43293
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME --shell /bin/bash \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME

# install oh-my-bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended \
  && echo "OSH_THEME=\"iterate\"" >> $HOME/.bashrc

# persistent history file
RUN sudo mkdir /history \
  && sudo touch /history/.bash_history \
  && sudo chown -R $USERNAME:$USERNAME /history \
  && echo "export PROMPT_COMMAND='history -a' && export HISTFILE=/history/.bash_history" >> $HOME/.bashrc

# install GH CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo apt-get update \
  && sudo apt-get install -y gh \
  && sudo rm -rf /var/lib/apt/lists/* \
  && /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o /tmp/github_api_key.txt /secrets/github_api_key.txt.gpg \
  && gh auth login --with-token < /tmp/github_api_key.txt \
  && rm /tmp/github_api_key.txt \
  && echo "export GH_EDITOR=code" >> $HOME/.bashrc \
  && echo "$(gh completion -s bash)" >> ~/.bashrc

# deploy wakatime API key
RUN /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o /tmp/wakatime_api_key.txt /secrets/wakatime_api_key.txt.gpg \
  && echo "export WAKATIME_API_KEY=$(cat /tmp/wakatime_api_key.txt)" >> $HOME/.bashrc \
  && rm /tmp/wakatime_api_key.txt

# deploy SSH keys and config
RUN mkdir -m 0700 $HOME/.ssh \
  && mkdir -m 0755 $HOME/.ssh/sockets \
  && /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o $HOME/.ssh/config /secrets/config.gpg \
  && chmod 0644 $HOME/.ssh/config \
  && /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o $HOME/.ssh/id_ed25519_nvidia /secrets/id_ed25519_nvidia.gpg \
  && chmod 0600 $HOME/.ssh/id_ed25519_nvidia \
  && /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o $HOME/.ssh/id_ed25519_nvidia.pub /secrets/id_ed25519_nvidia.pub.gpg \
  && chmod 0644 $HOME/.ssh/id_ed25519_nvidia.pub

# deploy git config and GPG keys
RUN /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o /tmp/github_signkey.asc /secrets/github_signkey.asc.gpg \
  && gpg --batch --pinentry-mode loopback --import /tmp/github_signkey.asc \
  && rm /tmp/github_signkey.asc \
  && /secrets/secrets.py decrypt --passphrase="$PASSPHRASE" -o $HOME/.gitconfig /secrets/.gitconfig.gpg