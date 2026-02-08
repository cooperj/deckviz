# Setup Zenoh bridge
ENV ZENOH_BRIDGE_VERSION=1.7.2
RUN cd /tmp; \
    curl -L -O https://github.com/eclipse-zenoh/zenoh-plugin-ros2dds/releases/download/${ZENOH_BRIDGE_VERSION}/zenoh-plugin-ros2dds-${ZENOH_BRIDGE_VERSION}-x86_64-unknown-linux-gnu-standalone.zip; \
    unzip zenoh-plugin-ros2dds-*.zip && \
    mv zenoh-bridge-ros2dds /usr/local/bin/ && \
    chmod +x /usr/local/bin/zenoh-bridge-ros2dds && \
    ldconfig && \
    rm -rf zenoh-*
