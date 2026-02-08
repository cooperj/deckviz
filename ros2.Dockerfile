ARG BASE_IMAGE=ros:humble
ARG ROS_DISTRO=humble
FROM ${BASE_IMAGE} AS base

USER root
ENV ROS_DISTRO=${ROS_DISTRO}
ENV DEBIAN_FRONTEND=noninteractive

# Copy the list of APT packages to be installed from the local directory to the container
COPY .docker/ros2-apt-packages.lst /tmp/apt-packages.lst

# Update the package list, upgrade installed packages, install the packages listed in apt-packages.lst,
# remove unnecessary packages, clean up the APT cache, and remove the package list to reduce image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    envsubst < /tmp/apt-packages.lst > /tmp/apt-packages.expanded && \
    apt-get install -y --no-install-recommends $(cat /tmp/apt-packages.expanded) && \
    apt-get purge -y gettext-base && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

# Install VirtualGL
RUN curl -L -O https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/virtualgl_3.1.1_amd64.deb && \
    apt-get update && \
    apt-get -y install ./virtualgl_3.1.1_amd64.deb && \
    rm virtualgl_3.1.1_amd64.deb && rm -rf /var/lib/apt/lists/* 

RUN groupadd --gid 1002 vglusers 

ENV VGL_ISACTIVE=1
ENV VGL_FPS=25
ENV VGL_COMPRESS=0
ENV VGL_DISPLAY=egl
ENV VGL_WM=1
ENV VGL_PROBEGLX=0
ENV LD_PRELOAD=/usr/lib/libdlfaker.so:/usr/lib/libvglfaker.so

# Add user groups
RUN usermod -a -G dialout $USERNAME &&\
    usermod -a -G video $USERNAME &&\
    usermod -a -G audio $USERNAME &&\
    usermod -a -G plugdev $USERNAME &&\
    usermod -a -G staff $USERNAME &&\
    usermod -a -G sudo $USERNAME &&\
    usermod -a -G input $USERNAME &&\
    usermod -a -G vglusers $USERNAME

# The dependencies stage sets up the base image for various dependencies that are not ROS packages. 
# This stage is used to build a foundation with all necessary libraries and tools required.
FROM base AS dependencies

# Setup Zenoh bridge
ENV ZENOH_BRIDGE_VERSION=1.7.2
RUN cd /tmp; \
    curl -L -O https://github.com/eclipse-zenoh/zenoh-plugin-ros2dds/releases/download/${ZENOH_BRIDGE_VERSION}/zenoh-plugin-ros2dds-${ZENOH_BRIDGE_VERSION}-x86_64-unknown-linux-gnu-standalone.zip; \
    unzip zenoh-plugin-ros2dds-*.zip && \
    mv zenoh-bridge-ros2dds /usr/local/bin/ && \
    chmod +x /usr/local/bin/zenoh-bridge-ros2dds && \
    ldconfig && \
    rm -rf zenoh-*

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    apt update && \
    rosdep --rosdistro=${ROS_DISTRO} update

# now also copy in all sources and build and install them
FROM dependencies AS workspace

# Config pipx
RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath
    
# Switch to the ros user and then configure the environment
USER ros

# Add a custom prompt, tmux configuration and source ros install
ENV PATH=/home/$USERNAME/.local/bin:$PATH
RUN echo "export PS1='\[\e[0;33m\]deckviz ➜ \[\e[0;32m\]\u@\h\[\e[0;34m\]:\w\[\e[0;37m\]\$ '" >> ~/.bashrc

# setup tmule 
RUN /home/${USERNAME}/.local/bin/pipx install tmule

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/usr/games:$PATH"' >> ~/.bashrc

# sort out dotfiles
COPY ./.docker/tmux.conf /home/ros/.tmux.conf
RUN echo "alias cls=clear" >> ~/.bashrc
RUN echo "alias q=exit" >> ~/.bashrc
RUN echo "alias spheres=/opt/VirtualGL/bin/glxspheres64" >> ~/.bashrc
RUN echo ". /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

WORKDIR /home/ros/ws
ENV SHELL=/bin/bash