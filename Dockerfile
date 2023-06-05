FROM  ubuntu:22.04 as builder

USER  root


ENV VER_LIBDEFLATE="v1.18"
ENV VER_ISAL="v2.30.0"
ENV VER_FASTP="v0.23.4"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -yq update --fix-missing
RUN apt-get install -yq --no-install-recommends locales
RUN apt-get -y install wget
RUN apt-get -y install make
RUN apt-get -y install cmake
RUN apt-get -y install autoconf
RUN apt-get -y install libtool-bin
RUN apt-get -y install nasm
RUN apt-get -y install g++


RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8


# build tools from other repos
ADD build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -yq update --fix-missing
RUN apt-get install -yq --no-install-recommends \
locales 

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8


RUN mkdir -p $OPT
COPY --from=builder $OPT $OPT

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]