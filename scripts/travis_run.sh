#!/bin/bash
set -e

./scripts/get_meta.sh > meta_files.list
which python
python ./scripts/get_urls.py meta_files.list

mv data.yml data_$TRAVIS_OS_NAME.yml
cat data_$TRAVIS_OS_NAME.yml
