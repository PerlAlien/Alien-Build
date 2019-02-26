ARG cip_tag=default

FROM plicease/ciperl:$cip_tag

RUN apt-get update -y               \
  && apt-get install -y             \
    pkg-config                      \
  && rm -rf /var/lib/apt/lists/*

RUN bash -c 'set -ex; cpanm -n Test2::V0; rm -rf ~/.cpanm'

ADD Alien-Build-*.tar.gz .
RUN bash -c 'set -ex; cd Alien-Build-*; cpanm -n --install .; rm -rf ~/.cpanm; cd ..; rm -rf Alien-Build-*'

COPY t/docker/needs-Alien-unzip/ ./
CMD prove -lvm *.t
