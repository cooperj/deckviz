# Create a non-root user for running ROS inside the container
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Delete the Ubuntu account if its there, to prevent issues with jazzy.
RUN id -u ubuntu >/dev/null 2>&1 && userdel -r ubuntu || true

# Create the user and group if they don't exist, set permissions, and add sudo support
RUN set -e; \
    # Create group if it doesn't exist
    if ! getent group ${USER_GID} >/dev/null; then \
        groupadd --gid ${USER_GID} ${USERNAME}; \
    fi; \
    # Create user if it doesn't exist
    if ! id -u ${USERNAME} >/dev/null 2>&1; then \
        useradd -m -d /home/${USERNAME} -s /bin/bash \
            --uid ${USER_UID} \
            --gid ${USER_GID} \
            ${USERNAME}; \
    fi; \
    # Fix ownership and permissions
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}; \
    chmod 700 /home/${USERNAME}; \
    # Give sudo privileges without password
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Add user groups
RUN usermod -a -G dialout $USERNAME &&\
    usermod -a -G video $USERNAME &&\
    usermod -a -G audio $USERNAME &&\
    usermod -a -G plugdev $USERNAME &&\
    usermod -a -G staff $USERNAME &&\
    usermod -a -G sudo $USERNAME &&\
    usermod -a -G input $USERNAME &&\
    usermod -a -G vglusers $USERNAME
