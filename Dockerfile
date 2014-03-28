FROM phusion/baseimage:0.9.9
MAINTAINER Open Knowledge System Administrators

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Set up APT
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu/ precise universe' >> /etc/apt/sources.list
RUN apt-get -q -y update

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
  build-essential \
  cpanminus \
  git \
  gnupg \
  graphviz \
  libexpat1-dev \
  libgd2-noxpm-dev \
  libpq-dev \
  nginx-light \
  perl-modules \
  postfix \
  procmail \
  razor \
  spamassassin \
  spawn-fcgi

# Set up environment
ENV PERL_MM_USE_DEFAULT 1
ENV HOME /root
ENV RT rt-4.2.3
ENV RTSRC ${RT}.tar.gz

# Install RT
RUN mkdir /src
WORKDIR /src
ADD http://download.bestpractical.com/pub/rt/release/${RTSRC} /src/${RTSRC}
RUN tar xzpvf /src/${RTSRC}
RUN ln -s /src/${RT} /src/rt
WORKDIR /
RUN cd /src/${RT} && ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz
RUN make -C /src/${RT} testdeps 2>/dev/null | fgrep ...MISSING | cut -d' ' -f1 | sort -u | xargs cpanm
RUN make -C /src/${RT} install
ADD ./scripts/rtcron /usr/bin/rtcron

# Add system service config
ADD ./etc/nginx.conf /etc/nginx/nginx.conf
ADD ./etc/crontab.root /var/spool/cron/crontabs/root

# Configure Postfix
ADD ./etc/postfix /etc/postfix
RUN chown -R root:root /etc/postfix
RUN newaliases
RUN mkdir -m 1777 /var/log/procmail
ADD ./etc/logrotate.procmail /etc/logrotate.d/procmail

# Build RT and extensions
ADD ./scripts/installext.sh /src/installext.sh
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-mergeusers
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-resetpassword
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-activityreports
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-spawnlinkedticketinqueue
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-commandbymail
RUN /src/installext.sh https://github.com/bestpractical/rt-extension-repeatticket
RUN cp /src/rt-extension-repeatticket/bin/rt-repeat-ticket /opt/rt4/sbin
RUN mkdir -p /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky
ADD ./misc/MakeClicky /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky/Default

# Configure RT
ADD ./RT_SiteConfig.pm /opt/rt4/etc/RT_SiteConfig.pm
RUN mv /opt/rt4/var /data
RUN ln -s /data /opt/rt4/var

# Add system services
RUN mkdir /var/log/rt4 /var/log/spamd
ADD ./svc /etc/service
CMD ["/sbin/my_init"]

VOLUME ["/data"]
EXPOSE 25
EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# vim:ts=8:noet:
