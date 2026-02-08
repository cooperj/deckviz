# Install VirtualGL

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        dirmngr && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L -O https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/virtualgl_3.1.1_amd64.deb && \
    apt-get update && \
    apt-get -y install ./virtualgl_3.1.1_amd64.deb && \
    rm virtualgl_3.1.1_amd64.deb && rm -rf /var/lib/apt/lists/* 


RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg && \
    curl -L -o /tmp/virtualgl.deb \
        https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/virtualgl_3.1.1_amd64.deb && \
    apt-get install -y /tmp/virtualgl.deb && \
    rm /tmp/virtualgl.deb && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1002 vglusers 

ENV VGL_ISACTIVE=1
ENV VGL_FPS=25
ENV VGL_COMPRESS=0
ENV VGL_DISPLAY=egl
ENV VGL_WM=1
ENV VGL_PROBEGLX=0
ENV LD_PRELOAD=/usr/lib/libdlfaker.so:/usr/lib/libvglfaker.so

# Add vglusers to ros user
RUN usermod -a -G vglusers ${USERNAME}
