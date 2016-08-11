FROM ubuntu:14.04
EXPOSE 8080

ENV DEBIAN_FRONTEND noninteractive

# 
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git \
        libpq-dev \
        memcached \
        nodejs \
        postgresql \
        redis-server \
        vim

#

# 
#RUN gem install bundler && rbenv rehash

# 
RUN sed -i 's/^#\(unix_socket_permissions\s*=.*\)$/\1/' /etc/postgresql/9.3/main/postgresql.conf

# 
RUN service postgresql start && su postgres -s /bin/bash -c "psql -c 'CREATE USER classroom_user; ALTER USER classroom_user CREATEDB'"

# 
RUN useradd --create-home classroom_user
USER classroom_user
WORKDIR /home/classroom_user

# https://github.com/rbenv/rbenv#installation
# https://github.com/rbenv/ruby-build/wiki
RUN git clone https://github.com/rbenv/rbenv.git /home/classroom_user/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /home/classroom_user/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/classroom_user/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> /home/classroom_user/.bashrc
