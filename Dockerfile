FROM centos:7

MAINTAINER Michał Iżewski, m.izewski@gmail.com

#add EPEL Repository
RUN yum -q --disablerepo=extras --disablerepo=updates -y update
RUN yum install -y http://repo.percona.com/centos/7/RPMS/x86_64/Percona-Server-shared-56-5.6.49-rel89.0.1.el7.x86_64.rpm
RUN yum install -y http://repo.percona.com/centos/7/RPMS/x86_64/Percona-Server-client-56-5.6.49-rel89.0.1.el7.x86_64.rpm
RUN rpm --quiet -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -q --disablerepo=extras --disablerepo=updates install -y wget vim tar cronie postgresql-libs initscripts unixODBC rsync
RUN rpm --quiet -Uhv http://sphinxsearch.com/files/sphinx-2.2.11-1.rhel7.x86_64.rpm
RUN yum -q clean -y all

RUN wget http://sphinxsearch.com/files/dicts/ru.pak -P /var/lib/sphinx/_dict
RUN wget http://sphinxsearch.com/files/dicts/en.pak -P /var/lib/sphinx/_dict
RUN wget http://sphinxsearch.com/files/dicts/de.pak -P /var/lib/sphinx/_dict

RUN localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 && \
    localedef -i de_DE -f UTF-8 de_DE.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV RSYNC NO
ENV RSYNC_VOLUME /var/lib/sphinx
ENV RSYNC_READONLY ${RSYNC_READONLY:-yes}
ENV RSYNC_OWNER ${RSYNC_OWNER:-sphinx}
ENV RSYNC_GROUP ${RSYNC_GROUP:-sphinx}
ENV RSYNC_ALLOW ${RSYNC_ALLOW:-192.168.0.0/16 172.16.0.0/12}

# expose ports
EXPOSE 9306 9312 873

RUN rm -rf /etc/sphinx
RUN rm -rf /var/spool/cron/sphinx

VOLUME ["/etc/sphinx", "/var/spool/cron", "/var/lib/sphinx", "/var/log/sphinx"]
 
ENTRYPOINT ["/entrypoint.sh"]

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["sphinx", "indexer"]
