ARG USERNAME
ARG USER_UID
ARG USER_GID

# Delete the Ubuntu account if it exists, to prevent issues with jazzy.
# RUN set -e; \
#     if id -u ubuntu >/dev/null 2>&1; then \
#         echo "Removing existing ubuntu user"; \
#         userdel -r ubuntu || true; \
#     fi; \
#     if getent group 1000 >/dev/null 2>&1; then \
#         GROUP_NAME="$(getent group 1000 | cut -d: -f1)"; \
#         if [ "${GROUP_NAME}" != "${USERNAME}" ]; then \
#             echo "Deleting existing group ${GROUP_NAME} (GID 1000)"; \
#             groupdel "${GROUP_NAME}" || true; \
#         fi; \
#     fi

# Create the group and user
RUN set -e; \
    groupadd --gid "${USER_GID}" "${USERNAME}" 2>/dev/null || true; \
    useradd \
      --uid "${USER_UID}" \
      --gid "${USER_GID}" \
      --create-home \
      --home-dir "/home/${USERNAME}" \
      --shell /bin/bash \
      "${USERNAME}"

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
