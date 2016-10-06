FROM centos:7
MAINTAINER "Russell Endicott" <rendicott@gmail.com>

RUN yum install git -y
RUN yum install ruby -y
RUN yum install gcc ruby-devel -y 
RUN yum install zlib-devel -y
RUN yum groupinstall 'Development Tools' -y
RUN yum install wget -y
RUN gem install bundle
RUN gem install byebug -v '9.0.6'
RUN git clone https://github.com/chrisevett/poolsclosed.git /opt/poolsclosed
RUN ls -al /opt/poolsclosed

RUN bundle install --gemfile=/opt/poolsclosed/Gemfile

RUN mkdir /data
RUN \
  cd /tmp && \
  wget http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  make && \
  make install && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /etc/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable* && \
  sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
  sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis.conf

RUN echo "#!/bin/bash" > /opt/startup.sh
RUN echo "/usr/local/bin/redis-server /etc/redis/redis.conf --daemonize yes" >> /opt/startup.sh
RUN echo "pushd /opt/poolsclosed" >> /opt/startup.sh
RUN echo "ruby -Ilib bin/poolsclosed" >> /opt/startup.sh
RUN chmod +x /opt/startup.sh

EXPOSE 42069
EXPOSE 6379
EXPOSE 22

WORKDIR "/data"
COPY config.yml /opt/poolsclosed/config.yml
WORKDIR "/opt/poolsclosed"
CMD ["/opt/startup.sh"]
