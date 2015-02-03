FROM phusion/baseimage:0.9.10
MAINTAINER Justin Dossey <justin.dossey@newcontext.com>

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Set up APT
RUN apt-get -q -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
  build-essential \
  ca-certificates \
  cpanminus \
  git \
  gnupg \
  graphviz \
  libexpat1-dev \
  libgd2-noxpm-dev \
  libpq-dev \
  mailutils \
  nginx-light \
  perl-modules \
  postfix \
  procmail \
  razor \
  spamassassin \
  spawn-fcgi \
  libgd-dev \
  libgd-text-perl \
  libgd-graph-perl \
  libsasl2-2 \
  libsasl2-modules \
  telnet \
  vim && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Set up environment
ENV PERL_MM_USE_DEFAULT 1
ENV HOME /root
ENV RT rt-4.2.9
ENV RTSRC ${RT}.tar.gz
ENV GITHUB https://github.com/bestpractical

COPY ./scripts/rtcron /usr/bin/rtcron
COPY ./scripts/rtinit /usr/bin/rtinit
COPY ./scripts/rtdata /usr/bin/rtdata

COPY ./scripts/installext.sh /src/installext.sh

# Add system service config
COPY ./etc/nginx.conf /etc/nginx/nginx.conf
COPY ./etc/crontab.root /var/spool/cron/crontabs/root

# Configure Postfix
COPY ./etc/postfix /etc/postfix
COPY ./etc/logrotate.procmail /etc/logrotate.d/procmail
COPY scripts/postfixinit /etc/my_init.d/10_update_postfix_config.sh

# Autoconfigure cpan
RUN echo q | /usr/bin/perl -MCPAN -e shell

# Install Capture::Tiny regardless of test failures for now
RUN cpan -f Capture::Tiny

# Install RT
RUN mkdir -p /src && \
  curl -sSL http://download.bestpractical.com/pub/rt/release/${RTSRC} | \
  tar -C /src -xz && \
  ln -s /src/${RT} /src/rt && \
  cd /src/${RT} && \
  ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz && \
  make -C /src/${RT} fixdeps && \
  make -C /src/${RT} testdeps && \
  make -C /src/${RT} install && \
  /src/installext.sh ${GITHUB}/rt-extension-mergeusers && \
  /src/installext.sh ${GITHUB}/rt-extension-resetpassword && \
  /src/installext.sh ${GITHUB}/rt-extension-activityreports && \
  /src/installext.sh ${GITHUB}/rt-extension-spawnlinkedticketinqueue && \
  /src/installext.sh ${GITHUB}/rt-extension-commandbymail && \
  rm -rf /src

RUN chown -R root:root /etc/postfix
RUN newaliases
RUN mkdir -m 1777 /var/log/procmail

# Build RT and extensions

RUN mkdir -p /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky
ADD ./misc/MakeClicky /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky/Default

# Configure RT
COPY ./RT_SiteConfig.pm /opt/rt4/etc/RT_SiteConfig.pm
RUN mv /opt/rt4/var /data
RUN ln -s /data /opt/rt4/var

# Add system services
RUN mkdir /var/log/rt4 /var/log/spamd
ADD ./svc /etc/service
CMD ["/sbin/my_init"]

VOLUME ["/data", "/etc/nginx/ssl", "/import"]
EXPOSE 25
EXPOSE 80
EXPOSE 443


# vim:ts=8:noet:
