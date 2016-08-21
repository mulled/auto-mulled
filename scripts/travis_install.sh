#!/bin/bash
set -e

if [[ $TRAVIS_OS_NAME = "linux" ]]
then
    curl -O https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
    bash Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/anaconda
else
    curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    bash Miniconda3-latest-MacOSX-x86_64.sh -b -p $HOME/anaconda
fi

export PATH=$HOME/anaconda/bin:$PATH
conda install -y conda-build
#conda install -y --file $SCRIPT_DIR/requirements.txt
