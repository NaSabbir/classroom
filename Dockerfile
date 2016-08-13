# https://devcenter.heroku.com/articles/stack
FROM ubuntu:14.04

# username that will run the classroom server
RUN useradd --create-home --skel=/dev/null ubuntu
RUN sed -i '/^root\s/a ubuntu\tALL=(ALL) NOPASSWD:ALL' /etc/sudoers
USER ubuntu

# without this, scripts/setup triggers:
# PG::InvalidParameterValue: ERROR:  new encoding (UTF8) is incompatible with the encoding of the template database (SQL_ASCII)
RUN sudo locale-gen "en_US.UTF-8" && sudo update-locale LANG=en_US.UTF-8

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
        software-properties-common \
        vim \
        wget

# Elasticsearch  
RUN wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - && \
    echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list && \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y elasticsearch

# install Ruby 2.3.1
# https://www.brightbox.com/blog/2016/01/06/ruby-2-3-ubuntu-packages/
RUN sudo apt-add-repository -y ppa:brightbox/ruby-ng && \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y ruby2.3 ruby2.3-dev && \
    sudo gem install bundler

# configure PostgreSQL
RUN sudo sed -i 's/^#\(unix_socket_permissions\s*=.*\)$/\1/' /etc/postgresql/9.3/main/postgresql.conf
RUN sudo service postgresql start && \
    sudo su postgres -s /bin/bash -c "psql -c 'CREATE USER ubuntu; ALTER USER ubuntu CREATEDB'" && \
    sudo service postgresql stop

# working directory
COPY . /home/ubuntu
WORKDIR /home/ubuntu
RUN sudo chown -R ubuntu:ubuntu /home/ubuntu

# run the setup script
RUN sudo service postgresql start && \
    bash -c -l ./script/setup && \
    sudo service postgresql stop

# start the rails server
EXPOSE 5000
CMD sudo service postgresql start ; bash -c -l ./script/server
