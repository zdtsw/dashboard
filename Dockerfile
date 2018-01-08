FROM dockerregistery.mycompany.com:18444:dashing/base:latest
MAINTAINER Wen Z

ARG project 
ENV PROJ ${project}

# when a new base image built with proxy setting, below two lines can be remove

ENV http_proxy=http://proxy.mycompany.com:8080
ENV https_proxy=http://proxy.mycompany.com:8080

ADD Gemfile_${PROJ} /dashing

COPY misc/${PROJ}/* /dashing/

ADD dashing.tar /dashing

#CMD find /assets /dashboards /jobs /widgets /keys /locale 

RUN  bundle install --gemfile Gemfile_${PROJ} && \
     ln -s /keys /dashing/keys

ENV no_proxy=.mycompany.com,localhost,127.0.0.1
ENV ftp_proxy=http://10.10.110.110:8080

WORKDIR /dashing

#hardcode to use 3030 for all dashing inside of container
CMD ["dashing", "start", "-p", "3030"]

