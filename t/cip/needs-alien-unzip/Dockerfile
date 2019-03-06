ARG cip_tag=default

FROM plicease/ciperl:$cip_tag

ADD Alien-Build-*.tar.gz .
RUN bash -c 'set -ex; cd Alien-Build-*; cpanm -n --install .; rm -rf ~/.cpanm; cd ..; rm -rf Alien-Build-*'

# alpine includes a unzip -> busybox symlink
RUN rm -rf /usr/bin/unzip

COPY t/cip/needs-alien-unzip/cpanfile ./cpanfile
RUN bash -c 'set -ex; cpanm --installdeps .; rm -rf ~/.cpanm'

COPY t/cip/needs-alien-unzip/ ./
CMD bash -c 'set -ex; prove -lvm'
