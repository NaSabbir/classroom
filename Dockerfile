FROM ubuntu:14.04
EXPOSE 8080

ENV DEBIAN_FRONTEND noninteractive

# without this, scripts/setup triggers:
# PG::InvalidParameterValue: ERROR:  new encoding (UTF8) is incompatible with the encoding of the template database (SQL_ASCII)
# HINT:  Use the same encoding as in the template database, or use template0 as template.
RUN locale-gen "en_US.UTF-8" && dpkg-reconfigure locales
ENV LANG "en_US.UTF-8"
ENV LC_ALL "en_US.UTF-8"
ENV LC_CTYPE "en_US.UTF-8"

# 
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        libpq-dev \
        libreadline-dev \
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
RUN useradd --create-home --home-dir=/home/classroom_user classroom_user && sed -i '/^root\s/a classroom_user\tALL=(ALL) NOPASSWD:ALL' /etc/sudoers
USER classroom_user
WORKDIR /srv/www

# https://github.com/rbenv/rbenv#installation
# https://github.com/rbenv/ruby-build/wiki
RUN git clone https://github.com/rbenv/rbenv.git /home/classroom_user/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /home/classroom_user/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/classroom_user/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> /home/classroom_user/.bashrc && \
    /home/classroom_user/.rbenv/bin/rbenv install 2.3.1 && \
    /home/classroom_user/.rbenv/bin/rbenv global 2.3.1 && \
    /home/classroom_user/.rbenv/shims/gem install bundler && \
    /home/classroom_user/.rbenv/bin/rbenv rehash
