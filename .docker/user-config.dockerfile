RUN echo "export PS1='\[\e[0;33m\]deckviz ➜ \[\e[0;32m\]\u@\h\[\e[0;34m\]:\w\[\e[0;37m\]\$ '" >> ~/.bashrc

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/usr/games:$PATH"' >> ~/.bashrc

# sort out dotfiles
COPY ./.docker/tmux.conf /home/ros/.tmux.conf
RUN echo "alias cls=clear" >> ~/.bashrc
RUN echo "alias q=exit" >> ~/.bashrc
RUN echo "alias spheres=/opt/VirtualGL/bin/glxspheres64" >> ~/.bashrc