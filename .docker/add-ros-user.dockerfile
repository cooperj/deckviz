ARG USERNAME
ARG USER_UID
ARG USER_GID

# Delete the Ubuntu account if its there, to prevent issues with jazzy.
RUN set -e; \
    if getent group "${USER_GID}" >/dev/null; then \
        GROUP_NAME="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        echo "Using existing group ${GROUP_NAME} (GID ${USER_GID})"; \
    else \
        GROUP_NAME="${USERNAME}"; \
        groupadd --gid "${USER_GID}" "${GROUP_NAME}"; \
        echo "Created group ${GROUP_NAME} (GID ${USER_GID})"; \
    fi; \
    echo "${GROUP_NAME}" > /tmp/ros-group-name 

# create ros user
RUN set -e; \
    if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
        useradd \
          --uid "${USER_UID}" \
          --gid "${USER_GID}" \
          --create-home \
          --home-dir "/home/${USERNAME}" \
          --shell /bin/bash \
          "${USERNAME}"; \
    fi

# Fix ownership and perms
RUN set -e; \
    GROUP_NAME="$(cat /tmp/ros-group-name)"; \
    chown -R "${USERNAME}:${GROUP_NAME}" "/home/${USERNAME}"; \
    chmod 700 "/home/${USERNAME}"

# Configure new user for sudo
RUN set -e; \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Add user groups
RUN usermod -a -G dialout ${USERNAME} &&\
    usermod -a -G video ${USERNAME} &&\
    usermod -a -G audio ${USERNAME} &&\
    usermod -a -G plugdev ${USERNAME} &&\
    usermod -a -G staff ${USERNAME} &&\
    usermod -a -G sudo ${USERNAME} &&\
    usermod -a -G input ${USERNAME}
