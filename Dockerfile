FROM ubuntu:latest

MAINTAINER Widget_An <anchunyu@heywhale.com>

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN apt-get update && apt-get -y upgrade && apt-get autoremove && apt-get autoclean
RUN apt-get -y install build-essential gfortran csh libpng-dev cmake wget m4 unzip git libpython3.8

RUN cd /opt && mkdir WRF && cd WRF && mkdir Downloads && mkdir Library

RUN cd /opt/WRF/Downloads \
    && wget https://file-1258430491.cos.ap-shanghai.myqcloud.com/hdf5-1.13.0.tar.gz \
    && tar -xvzf hdf5-1.13.0.tar.gz \
    && cd hdf5-1.13.0/ \
    && ./configure --prefix=/opt/WRF/Library --with-zlib --enable-hl --enable-fortran \
    && make check -j \
    && make install

ENV HDF5=/opt/WRF/Library
ENV LD_LIBRARY_PATH=/opt/WRF/Library/lib:$LD_LIBRARY_PATH

ENV CPPFLAGS=-I/opt/WRF/Library/include 
ENV LDFLAGS=-L/opt/WRF/Library/lib
RUN cd /opt/WRF/Downloads \
    && wget https://downloads.unidata.ucar.edu/netcdf-c/4.8.1/src/netcdf-c-4.8.1.tar.gz \
    && tar -xvzf netcdf-c-4.8.1.tar.gz \
    && cd netcdf-c-4.8.1 \
    && ./configure --prefix=/opt/WRF/Library --disable-dap \
    && make check -j \
    && make install

ENV PATH=/opt/WRF/Library/bin:$PATH
ENV NETCDF=/opt/WRF/Library/
ENV LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"

RUN cd /opt/WRF/Downloads \
    && wget https://downloads.unidata.ucar.edu/netcdf-fortran/4.5.3/netcdf-fortran-4.5.3.tar.gz \
    && tar -xvzf netcdf-fortran-4.5.3.tar.gz \
    && cd netcdf-fortran-4.5.3 \
    && ./configure --prefix=/opt/WRF/Library/ --disable-shared \
    && make check -j \
    && make install

ENV JASPERLIB=/opt/WRF/Library/lib
ENV JASPERINC=/opt/WRF/Library/include
RUN cd /opt/WRF/Downloads \
    && wget https://ece.engr.uvic.ca/~frodo/jasper/software/jasper-2.0.14.tar.gz \
    && tar -xvzf jasper-2.0.14.tar.gz \
    && cd jasper-2.0.14 \
    && cmake -G "Unix Makefiles" -H. -B./build -DCMAKE_INSTALL_PREFIX=/opt/WRF/Library/ \
    && cd build \
    && make -j \
    && make install 

ARG CC=gcc
ARG CXX=g++
ARG FC=gfortran
ARG F77=gfortran
RUN cd /opt/WRF/Downloads \
    && wget https://github.com/wrf-model/WRF/archive/refs/tags/v4.3.2.tar.gz \
    && tar -xvzf v4.3.2.tar.gz -C ../ \
    && cd ../WRF-4.3.2/ \
    && ./clean \
    && sh -c '/bin/echo -e "33" echo -e "1" |sh ./configure' \
    && ./compile em_real
ENV WRF_DIR=/opt/WRF/WRF-4.3.2

RUN cd /opt/WRF/Downloads \
    && wget http://www.mpich.org/static/downloads/3.4/mpich-3.4.tar.gz \
    && tar -xvzf mpich-3.4.tar.gz \
    && cd mpich-3.4 \
    && ./configure --prefix=/opt/WRF/Library/ --with-device=ch4:ofi \
    && make \
    && make install

RUN cd /opt/WRF/Downloads \
    && wget https://github.com/wrf-model/WPS/archive/v4.3.1.tar.gz \
    && tar -xvzf v4.3.1.tar.gz \
    && cd WPS-4.3.1 \
    && sh -c '/bin/echo -e "4" |sh ./configure' \
    && ./compile

RUN cd /opt/WRF/Downloads \
    && wget http://www2.mmm.ucar.edu/wrf/src/ARWpost_V3.tar.gz \
    && tar -xvzf ARWpost_V3.tar.gz -C /opt/WRF \
    && cd /opt/WRF/ARWpost \
    && ./clean \
    && sed -i -e 's/-lnetcdf/-lnetcdff -lnetcdf/g' /opt/WRF/ARWpost/src/Makefile \
    && sh -c '/bin/echo -e "3" |sh ./configure' \
    && sed -i -e 's/-C -P/-P/g' /opt/WRF/ARWpost/configure.arwp \
    && ./compile

RUN cd /opt/WRF/Downloads \
    && wget http://esrl.noaa.gov/gsd/wrfportal/domainwizard/WRFDomainWizard.zip \
    && mkdir /opt/WRF/WRFDomainWizard \
    && unzip WRFDomainWizard.zip -d /opt/WRF/WRFDomainWizard \
    && chmod +x /opt/WRF/WRFDomainWizard/run_DomainWizard

RUN cd /opt/WRF/Downloads \
    && wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
    && tar -xvzf geog_high_res_mandatory.tar.gz -C /opt/WRF
