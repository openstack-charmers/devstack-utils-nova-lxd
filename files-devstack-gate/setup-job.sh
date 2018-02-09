#!/bin/bash

# branch is master unless ZUUL_BRANCH is already set
# this script should be run by the jenkins user.

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

source ${_dir}/devstack-vars

mkdir -p $WORKSPACE

git clone $REPO_URL/$ZUUL_PROJECT $ZUUL_URL/$ZUUL_PROJECT \
	&& cd $ZUUL_URL/$ZUUL_PROJECT \
	&& git checkout remotes/origin/$ZUUL_BRANCH

cd $WORKSPACE \
	&& git clone --depth 1 $REPO_URL/openstack-infra/devstack-gate
