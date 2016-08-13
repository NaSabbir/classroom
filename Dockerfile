FROM ubuntu:14.04

# TCP port
EXPOSE 5000

# without this, scripts/setup triggers:
# PG::InvalidParameterValue: ERROR:  new encoding (UTF8) is incompatible with the encoding of the template database (SQL_ASCII)
RUN locale-gen "en_US.UTF-8" && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && update-locale LANG=en_US.UTF-8

# username that will run the classroom server
RUN useradd --create-home --skel=/dev/null ubuntu
RUN sed -i '/^root\s/a ubuntu\tALL=(ALL) NOPASSWD:ALL' /etc/sudoers
USER ubuntu

# Nodejs, PostgreSQL, Redis, Memcached, ...
RUN sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y \
        apt-transport-https \
        build-essential \
        curl \
        git \
        libpq-dev \
        libreadline-dev \
        memcached \
        nodejs \
        postgresql \
        redis-server \
        vim \
        wget

# Elasticsearch  
RUN wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - && \
    echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list && \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y elasticsearch

# install Ruby 2.3.1
# https://github.com/rbenv/rbenv#installation
# https://github.com/rbenv/ruby-build/wiki
RUN git clone https://github.com/rbenv/rbenv.git "$HOME"/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git "$HOME"/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME"/.bash_profile && \
    echo 'eval "$(rbenv init -)"' >> "$HOME"/.bash_profile && \
    "$HOME"/.rbenv/bin/rbenv install 2.3.1 && \
    "$HOME"/.rbenv/bin/rbenv global 2.3.1 && \
    "$HOME"/.rbenv/shims/gem install bundler && \
    "$HOME"/.rbenv/bin/rbenv rehash

# configure PostgreSQL
RUN sudo sed -i 's/^#\(unix_socket_permissions\s*=.*\)$/\1/' /etc/postgresql/9.3/main/postgresql.conf
RUN sudo service postgresql start && \
    sudo su postgres -s /bin/bash -c "psql -c 'CREATE USER ubuntu; ALTER USER ubuntu CREATEDB'" && \
    sudo service postgresql stop

# working directory
COPY . /mnt
WORKDIR /mnt
RUN sudo chown -R ubuntu:ubuntu /mnt/*

# run the setup script
RUN sudo service postgresql start && \
    bash -c -l ./script/setup && \
    sudo service postgresql stop

# start the rails server
CMD sudo service postgresql start ; bash -c -l ./script/server
