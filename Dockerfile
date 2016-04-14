FROM python:2.7-slim

# install the needed libraries and tools
RUN  apt-get update                          && \
     apt-get install -y build-essential \
                        gfortran        \
                        git             \
                        libfftw3-dev    \
                        make            \
                        subversion      \
                     --no-install-recommends

WORKDIR /usr/local/src

ADD compile_shifter.sh compile_shifter.sh
RUN git clone https://github.com/lichinka/cp2k.git && \
    cd cp2k                                        && \
    ./compile_shifter.sh

CMD ["/bin/bash"]
