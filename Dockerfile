FROM ubuntu:14.04
MAINTAINER Johannes M. Schleicher <schleicher@dsg.tuwien.ac.at>

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
RUN cd /root/src; tar xvf ruby-2.2.2.tar.gz
RUN cd /root/src/ruby-2.2.2; ./configure; make install

RUN gem update --system
RUN gem install bundler

# SqLite
RUN apt-get -y install sqlite3 libsqlite3-dev

# # Add Openstack nova client support

RUN apt-get -y install python python-dev software-properties-common python-pip
RUN pip install python-novaclient

# for a JS runtime
RUN apt-get install -y nodejs

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

# Add assets
RUN mkdir /dashboard
ADD ./ /dashboard


WORKDIR /dashboard

# RUN git clone https://github.com/tcnksm/docker-sinatra /root/sinatra
#RUN bundle install --jobs 5

EXPOSE 3000

CMD ["bash", "-c", "rails server -b 0.0.0.0"]
