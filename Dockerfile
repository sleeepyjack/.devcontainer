
# Use the [Choice] comment to indicate option arguments that should appear in VS Code UX. Use a comma separated list.
#
# [Choice] CUDA version: 11.6.2, 11.7.0
ARG VARIANT="11.7.0"
FROM nvcr.io/nvidia/cuda:${VARIANT}-devel-ubuntu20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# install base packages
RUN apt-get update \
  && apt-get install -y \
  ansible \
  sudo \
  locales \
  locales-all \
  software-properties-common \
  curl \
  wget \
  htop \
  git \
  vim \
  python3 \
  python3-dev \
  scons \
  && rm -rf /var/lib/apt/lists/*

# install g++-11
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
  && apt-get update \
  && apt-get install -y g++-11 \
  && rm -rf /var/lib/apt/lists/*

# install LLVM toolchain
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key \
  | apt-key add - \
  && apt-get update \
  && apt-get install -y \
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
  && rm -rf /var/lib/apt/lists/*

# install cmake
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
  | gpg --dearmor - \
  | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
  && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' \
  | tee /etc/apt/sources.list.d/kitware.list >/dev/null \
  && apt-get update \
  && rm /usr/share/keyrings/kitware-archive-keyring.gpg \
  && apt-get install -y kitware-archive-keyring cmake \
  && rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ADD ansible /ansible

ARG USERNAME=djuenger
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG ANSIBLE_VAULT_PASSWORD
ARG ANSIBLE_VAULT_PASSWORD_FILE=/tmp/.vault_password
ARG ANSIBLE_LOCALHOST_WARNING=false
ARG ANSIBLE_PYTHON_INTERPRETER=auto

RUN echo $ANSIBLE_VAULT_PASSWORD > $ANSIBLE_VAULT_PASSWORD_FILE

RUN ansible-playbook /ansible/playbooks/00-user.yaml
USER $USERNAME
RUN ansible-playbook /ansible/playbooks/20-ssh.yaml
RUN ansible-playbook /ansible/playbooks/30-git.yaml
RUN ansible-playbook /ansible/playbooks/40-waka.yaml
RUN ansible-playbook /ansible/playbooks/50-conda.yaml

# persistent history file
RUN sudo mkdir /history \
    && sudo touch /history/.bash_history \
    && sudo chown -R $USERNAME:$USERNAME /history \
    && echo "export PROMPT_COMMAND='history -a' && export HISTFILE=/history/.bash_history" >> /home/$USERNAME/.bashrc
