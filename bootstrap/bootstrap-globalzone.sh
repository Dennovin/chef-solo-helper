#!/bin/bash
# Bootstrap an ec2 system remotely via ssh

. $(dirname $0)/config.sh

HOST=$1
# Allow specifying the hostname on the command line - this is used to
# temporarily set the hostname on the system so that chef knows what node name
# to use
NODENAME=$2

REPOS=$3

# Utility functions
msg() { echo " * $@"; }
err() { msg $@; exit 100; }
safe() { "$@" || err "cannot $@"; }

SSH_OPTS=
[[ -n $SSH_KEY ]] && SSH_OPTS="-i $SSH_KEY"

if [[ -n $REPOS ]]; then
	msg "Added Apropo pkg repos"
	ssh $SSH_OPTS $USERNAME@$HOST pkg set-publisher -g http://pkg.omniti.com/custom custom.omniti.com
	ssh $SSH_OPTS $USERNAME@$HOST pkg set-publisher -g http://pkg.omniti.com/restricted restricted.omniti.com
	msg "Installing needed PKG's"
	ssh $SSH_OPTS $USERNAME@$HOST pkg install ruby-18 OMNIgit OMNIchef
fi

msg "Making bootstrap dir on the server"
safe ssh $SSH_OPTS $USERNAME@$HOST mkdir -p $BOOTSTRAP_PATH

msg "Copying key"
safe scp $SSH_OPTS $KEY $USERNAME@$HOST:$BOOTSTRAP_PATH

msg "Copying bootstrap script"
safe scp $SSH_OPTS $BOOTSTRAP_SCRIPT $USERNAME@$HOST:$BOOTSTRAP_PATH

msg "Copying configuration"
safe scp $SSH_OPTS config.sh $USERNAME@$HOST:$BOOTSTRAP_PATH

if [[ -n $NODENAME ]]; then
    msg "Setting hostname on the server"
    safe ssh $SSH_OPTS $USERNAME@$HOST sudo hostname $NODENAME
fi

msg "Running bootstrap script on $HOST as root"
safe ssh $SSH_OPTS $USERNAME@$HOST sudo $BOOTSTRAP_PATH/$BOOTSTRAP_SCRIPT
