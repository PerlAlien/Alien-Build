ARG cip_tag=default

FROM plicease/ciperl:$cip_tag

ADD Alien-Build-*.tar.gz .
RUN bash -c 'set -ex; cd Alien-Build-*; cpanm -n --install .; rm -rf ~/.cpanm; cd ..; rm -rf Alien-Build-*'

COPY t/cip/needs-alien-unzip/ ./
RUN bash -c 'set -ex; cpanm --installdeps .; rm -rf ~/.cpanm'

CMD bash -c 'set -ex; prove -lvm'
