#!/bin/bash

# branch is master unless ZUUL_BRANCH is already set
# this script should be run by the jenkins user.

export REPO_URL=https://git.openstack.org
export ZUUL_URL=$HOME/workspace-cache
export ZUUL_REF=HEAD
export WORKSPACE=$HOME/workspace/testing
mkdir -p $WORKSPACE

export ZUUL_PROJECT=openstack/nova-lxd
export ZUUL_BRANCH=${ZUUL_BRANCH:-master}

git clone $REPO_URL/$ZUUL_PROJECT $ZUUL_URL/$ZUUL_PROJECT \
	&& cd $ZUUL_URL/$ZUUL_PROJECT \
	&& git checkout remotes/origin/$ZUUL_BRANCH

cd $WORKSPACE \
	&& git clone --depth 1 $REPO_URL/openstack-infra/devstack-gate
