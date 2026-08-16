FROM centos:7

MAINTAINER Michał Iżewski, m.izewski@gmail.com

# CentOS 7 is EOL: mirrorlist.centos.org is dead (DNS doesn't even resolve anymore).
# Point base/updates/extras at the vault so `yum` still has something to talk to.
RUN sed -i \
    -e 's/^mirrorlist=/#mirrorlist=/' \
    -e 's/^#baseurl=http:\/\/mirror.centos.org/baseurl=https:\/\/vault.centos.org/' \
    /etc/yum.repos.d/CentOS-*.repo

#add EPEL Repository
RUN yum -q --disablerepo=extras --disablerepo=updates -y update

# Percona publishes no checksums for these; pin the sha256 of what we fetch today so a
# future swap on repo.percona.com gets caught at build time instead of trusted blindly.
RUN curl -fsSL -o /tmp/percona-shared.rpm https://repo.percona.com/centos/7/RPMS/x86_64/Percona-Server-shared-56-5.6.49-rel89.0.1.el7.x86_64.rpm && \
    echo "876bc5e73c6057b00c8f18685f5a6a47f4c52d6a86d157ea99e4b57c864502a0  /tmp/percona-shared.rpm" | sha256sum -c - && \
    yum install -y /tmp/percona-shared.rpm && \
    rm -f /tmp/percona-shared.rpm
RUN curl -fsSL -o /tmp/percona-client.rpm https://repo.percona.com/centos/7/RPMS/x86_64/Percona-Server-client-56-5.6.49-rel89.0.1.el7.x86_64.rpm && \
    echo "a6356e964a7f4021354044993a5e3a4ace808c2be3d3b6527c8eae530296847e  /tmp/percona-client.rpm" | sha256sum -c - && \
    yum install -y /tmp/percona-client.rpm && \
    rm -f /tmp/percona-client.rpm

# epel-release-latest-7 was removed from dl.fedoraproject.org post-EOL; pull the last
# EPEL7 release straight from the archive instead, with a pinned checksum.
RUN curl -fsSL -o /tmp/epel-release.rpm https://archives.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm && \
    echo "e2d5ffdd4cfe09dde17018a31d100db611abe88cc6761d9bdc0c1f41efaa5aa0  /tmp/epel-release.rpm" | sha256sum -c - && \
    rpm --quiet -Uvh /tmp/epel-release.rpm && \
    rm -f /tmp/epel-release.rpm

RUN yum -q --disablerepo=extras --disablerepo=updates install -y wget vim tar cronie postgresql-libs initscripts unixODBC rsync

RUN curl -fsSL -o /tmp/sphinx.rpm https://sphinxsearch.com/files/sphinx-2.2.11-1.rhel7.x86_64.rpm && \
    echo "959b04eb3f7fb2314d7a2702b61e9b3e627b66b1a8574dece21c0592be1b90e2  /tmp/sphinx.rpm" | sha256sum -c - && \
    rpm --quiet -Uhv /tmp/sphinx.rpm && \
    rm -f /tmp/sphinx.rpm

RUN yum -q clean -y all

RUN wget https://sphinxsearch.com/files/dicts/ru.pak -P /var/lib/sphinx/_dict
RUN wget https://sphinxsearch.com/files/dicts/en.pak -P /var/lib/sphinx/_dict
RUN wget https://sphinxsearch.com/files/dicts/de.pak -P /var/lib/sphinx/_dict

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
