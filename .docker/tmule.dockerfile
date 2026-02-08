# setup tmule 
RUN PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')") && \
    if [ "$(echo $PY_VERSION | awk -F. '{print $1$2}')" -ge 312 ]; then \
        pip3 install --break-system-packages -U tmule; \
    else \
        pip3 install -U tmule; \
    fi