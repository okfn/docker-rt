FROM ubuntu:12.04
MAINTAINER Open Knowledge System Administrators

ENV RT rt-4.2.1

# Set up APT
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu/ precise universe' >> /etc/apt/sources.list
RUN apt-get -q -y update

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install supervisor nginx-light perl-modules cpanminus build-essential libexpat1-dev libpq-dev cron postfix git spamassassin razor procmail logrotate graphviz gnupg libgd2-noxpm-dev

# Install the RT source and scripts
ENV RTSRC ${RT}.tar.gz
ADD http://download.bestpractical.com/pub/rt/release/${RTSRC} /src/${RTSRC}
ADD ./rt-perl-modules /src/rt-perl-modules

# Imstall dependencies
RUN cpanm --force GD ## GD fails one of the tests
RUN < /src/rt-perl-modules xargs cpanm

ADD ./build_rt.sh /src/build_rt.sh
ADD ./config_rt.sh /src/config_rt.sh

# Add system service config
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./crontab.root /var/spool/cron/crontabs/root

# Configure Postfix
ADD ./main.cf /etc/postfix/main.cf
ADD ./aliases /etc/postfix/aliases
RUN chown root:root /etc/postfix/main.cf /etc/postfix/aliases
RUN newaliases

ADD ./procmailrc.rt /etc/postfix/procmailrc.rt
RUN mkdir /var/log/procmail
RUN chmod 1777 /var/log/procmail
ADD ./logrotate.procmail /etc/logrotate.d/procmail

# Build RT and extensions
RUN sh /src/build_rt.sh
ADD ./MakeClicky /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky/Default

# Configurate RT
ADD ./RT_SiteConfig.pm /opt/rt4/etc/RT_SiteConfig.pm
RUN sh /src/config_rt.sh

# Make cron not complain
RUN touch /etc/mtab

ADD ./start_rt.sh /start_rt.sh
CMD ["/start_rt.sh"]

# vim:ts=8:noet:
