#!/bin/bash

function init() {
	echo "---- fetch recipes ----"
	if [ -d bioconda-recipes ]; then
		echo "=> updating local repository"
		cd bioconda-recipes
		git pull --quiet
		cd ..
	else
		echo "=> cloning remote"
		git clone --quiet https://github.com/bioconda/bioconda-recipes.git
	fi

	echo "---- fetch repository data from anaconda ----"
	rm -f repodata.json repodata.json.bz2
	wget --quiet https://conda.anaconda.org/bioconda/linux-64/repodata.json.bz2
	bzip2 -d repodata.json.bz2
}

function affected_packages() {
	cd bioconda-recipes
	git log --name-only --pretty="" --since="25 hours ago" | grep -E '^recipes/.*/meta.yaml' | sed 's#recipes/\([^/]*\)/.*#\1#' | sort | uniq
	cd ..
}

function condaversions_for() {
	PKG=$1
	jq '.packages|map(select(.name == "'$1'"))|map(.version + "--" + .build)' repodata.json
}

function quayversions_for() {
	PKG=$1
	(wget --quiet -O - "https://quay.io/api/v1/repository/mulled/$PKG" || echo '{"tags": {}}') | jq '.tags | keys'
}

function new_versions_for() {
	PKG=$1
	CONDA=$(condaversions_for $PKG)
	QUAY=$(quayversions_for $PKG)

	jq -n "$CONDA - $QUAY" 
}

function involucro_params_for() {
	PKG=$1
	new_versions_for $1 | jq --raw-output 'map("-set PACKAGE='$PKG' -set TAG=" + . + " -set VERSION=" + split("--")[0] + " -set BUILD=" + split("--")[1]) | join("\n")'
}

set -e
init

AFFECTED=$(affected_packages)

if [ "$TRAVIS_SECURE_ENV_VARS" = "true" -a "$TRAVIS_BRANCH" = "master" -a "$TRAVIS_PULL_REQUEST" = "false" ]; then
	COMMANDS="build push"

	echo "---- create repositories on quay ----"
	for i in $AFFECTED; do
		echo -n "* $i : "
		(
			echo "{"
			echo '"namespace": "'$NAMESPACE'",'
			echo '"visibility": "public",'
			echo '"description": "Auto-generated by [mulled/auto-mulled](https://github.com/mulled/auto-mulled)",'
			echo '"repository": "'$i'"'
			echo "}"
		) | curl --fail \
			-X POST \
			-HAuthorization:Bearer\ $QUAY_TOKEN \
			-d @- \
			-HContent-Type:application/json \
			https://quay.io/api/v1/repository \
			|| echo "  FAILED!"
		echo
	done

else
	COMMANDS="build"
fi

echo "---- package apps ----"

(for i in $(affected_packages); do involucro_params_for $i ; done) | xargs -I XX /bin/sh -c "./involucro XX $COMMANDS"
