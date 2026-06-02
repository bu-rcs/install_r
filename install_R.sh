#!/bin/bash


# Author: Katia
# Date: March 15, 2023
# Version 1.2
# 
# Install new version of R
#
# Notes: This script installs a new version of R
# It should be run from within version directory, i.e. /share/pkg.7/r/4.2.3
# the environment variable must be set, i.e export VERSION="4.2.3"

# Modified: April 30, 2024 - configure step modified - added flexblas option
# Modified: June 18, 2023 - modified for pkg.8 (alma8), use gcc/12.2.0 (current default gcc version 8.5.0)



MODULE_DIR="/share/pkg.8/r/$VERSION/"
INSTALL_DIR="/share/pkg.8/r/$VERSION/install"
SRC_DIR="/share/pkg.8/r/$VERSION/src"
BUILD_DIR="/share/pkg.8/r/$VERSION/build"

cd DIST;
# Download source from https://cran.r-project.org/
wget http://cran.r-project.org/src/base/R-4/R-$VERSION.tar.gz


# untar the sources
cd ../src
tar xzf ../DIST/R-$VERSION.tar.gz

# configure
cd ../build
module load texlive/2022
module load gcc/12.2.0
module load flexiblas/3.3.1

# The following is the original configure step (before April 30, 2024)
# ../src/R-$VERSION/configure --prefix=$INSTALL_DIR --enable-R-shlib --enable-memory-profiling --enable-R-profiling --with-valgrind-instrumentation=2 |& tee config.out

# April 30, 2024: add flexiblas option to allow switching between various blas implementations:
../src/R-$VERSION/configure --prefix=$INSTALL_DIR --enable-R-shlib --enable-memory-profiling --enable-R-profiling --with-valgrind-instrumentation=2 --with-blas="`pkg-config flexiblas --libs`" --with-lapack |& tee config.out


#build
make |&tee make.output
make install |&tee make.install.output
make check |&tee make.check.output



# Make a soft link to the man page
cd ../install
ln -s share/man man


# Add some Fortran shared library to make sure R starts without gcc module:
cd lib64/R/lib
cp /share/pkg.7/gcc/12.2.0/install/lib64/libgfortran.so.5.0.0 .
ln -s libgfortran.so.5.0.0 libgfortran.so.5
ln -s libgfortran.so.5 libgfortran.so

# For Rcpp package we also need stdc++
cp /share/pkg.7/gcc/12.2.0/install/lib64/libstdc++.so.6.0.30 .
ln -s libstdc++.so.6.0.30 libstdc++.so.6
ln -s libstdc++.so.6.0.30 libstdc++.so

cp /share/pkg.7/gcc/12.2.0/install/lib64/libgcc_s.so .
cp /share/pkg.7/gcc/12.2.0/install/lib64/libgcc_s.so.1 .


# Go back to the main install directory
cd ../../..


## Edit ldpaths file to point R to the default Java installation, so
## if Mike updates Java, it does not break rJava package and those that depend on it.
## Open the following file
#/share/pkg.8/r/$VERSION/install/lib64/R/etc/ldpaths
## Make the first line to be:
#: ${JAVA_HOME=/usr/java/default/jre}
javaversion=$(readlink /usr/java/latest)

javaversion=${javaversion##*/}
echo $javaversion

ed -s /share/pkg.8/r/$VERSION/install/lib64/R/etc/ldpaths <<EOF
1s/$javaversion/default
w
q
EOF
#--------------------------------------


#----------------------------
# Install R Bioconductor
#----------------------------

# Go back to the build directory (so we could save the output file there )
cd ../build
../install/bin/Rscript ../../install_bioconductor.R |&tee install_bioconductor.output



