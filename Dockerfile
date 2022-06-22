
# Use the [Choice] comment to indicate option arguments that should appear in VS Code UX. Use a comma separated list.
#
# [Choice] CUDA version: 11.6.2, 11.7.0
ARG VARIANT="11.7.0"
FROM nvcr.io/nvidia/cuda:${VARIANT}-devel-ubuntu20.04

RUN apt-get update && apt-get install -y ansible
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
RUN ansible-playbook /ansible/playbooks/10-apt.yaml
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
