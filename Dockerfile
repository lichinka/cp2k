FROM python:2.7-slim


##########################
## CUDA section
##
ENV CUDA_VERSION 7.0
LABEL com.nvidia.cuda.version="7.0"

RUN apt-get update                          && \
    apt-get install -y build-essential         \
                       gcc-4.9                 \
                       g++-4.9                 \
                       linux-headers-amd64     \
                       wget                    \
                    --no-install-recommends

WORKDIR /usr/local/src

RUN wget -q -O cuda_7.0.run http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run && \
    chmod +x cuda_7.0.run                         && \
    ./cuda_7.0.run --silent --toolkit --override

RUN echo "/usr/local/cuda/lib" >> /etc/ld.so.conf.d/cuda.conf   && \
    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
    ldconfig

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf   && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
    ldconfig

ENV PATH /usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda/lib:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}


##########################
## CP2K section
##
RUN  apt-get update                          && \
     apt-get install -y gfortran-4.9        	\
                        git             	\
                        libatlas-dev    	\
                        libfftw3-dev    	\
			liblapack-dev           \
			libmpich-dev    	\
			libscalapack-mpi-dev 	\
                        subversion      	\
                     --no-install-recommends

RUN git clone https://github.com/lichinka/cp2k.git && \
    cd cp2k                                        && \
    ./compile_shifter.sh

CMD ["/bin/bash"]
