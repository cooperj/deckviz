# syntax = devthefuture/dockerfile-x:v1.5.3

INCLUDE_ARGS .docker/config.env
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

INCLUDE .docker/add-ros-user.dockerfile
INCLUDE .docker/virtualgl.dockerfile

# The dependencies stage sets up the base image for various dependencies that are not ROS packages. 
# This stage is used to build a foundation with all necessary libraries and tools required.
FROM base AS dependencies

INCLUDE .docker/zenoh.dockerfile

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    apt update && \
    rosdep --rosdistro=${ROS_DISTRO} update

# now also copy in all sources and build and install them
FROM dependencies AS workspace

# Switch to the ros user and then configure the environment
USER ros
INCLUDE .docker/user-config.dockerfile
INCLUDE .docker/tmule.dockerfile

# Add a custom prompt, tmux configuration and source ros install
ENV PATH=/home/$USERNAME/.local/bin:$PATH
RUN echo ". /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

WORKDIR /home/ros/ws
ENV SHELL=/bin/bash

LABEL org.opencontainers.image.title="deckviz"
LABEL org.opencontainers.image.description="ROS2 for Steam Deck, For Teleoperation and Visualisation"
LABEL org.opencontainers.image.authors="Josh Cooper <hi@joshc.uk>"
LABEL org.opencontainers.image.url="https://github.com/cooperj/deckviz"
LABEL org.opencontainers.image.source="https://github.com/cooperj/deckviz"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Josh Cooper <hi@joshc.uk>"