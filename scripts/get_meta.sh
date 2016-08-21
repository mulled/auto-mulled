#!/bin/sh

git clone --quiet https://github.com/bioconda/bioconda-recipes.git
cd bioconda-recipes
git log --name-only --pretty="" --since="2 days ago" | grep -E '^recipes/.*/meta.yaml'
