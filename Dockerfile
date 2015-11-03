FROM ruby:2.2.0

MAINTAINER Johannes M. Schleicher <schleicher@dsg.tuwien.ac.at>

# Install packages for building ruby / pythong
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# SqLite
RUN apt-get -y install sqlite3 libsqlite3-dev

# for a JS runtime
RUN apt-get install -y nodejs


# # Add Openstack nova client support
#
#
RUN apt-get -y install python python-dev software-properties-common python-pip
# RUN curl https://pypi.python.org/packages/source/s/setuptools/setuptools-1.1.6.tar.gz | (cd /root;tar xvzf -;cd setuptools-1.1.6;python setup.py install)
# RUN easy_install pip
RUN pip install python-novaclient

# Add assets
RUN mkdir /dashboard
ADD ./ /dashboard
WORKDIR /dashboard

# RUN git clone https://github.com/tcnksm/docker-sinatra /root/sinatra
RUN bundle install

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
# CMD ["/usr/local/bin/foreman","start","-d","/root/sinatra"]