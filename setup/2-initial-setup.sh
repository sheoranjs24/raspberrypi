#!/usr/bin/expect -f
####################################################
# run as: sudo ./2-initial-setup.sh <username> <raspberryPiHostIp> [<ssh-public-key>]
# pre-requisite: create an ssh key for raspberryPi
####################################################

# Parameters
if [[ ($# -eq 2 || $# -eq 3) ]];
then
  export USERNAME=$1
  export RPI_HOSTNAME=$2
  if [[ $# -eq 3 ]];
  then
    export SSH_PUBLIC_KEY=$3
  else
    export SSH_PUBLIC_KEY=~/.ssh/id_rsa.pub
  fi
else
  echo "Illegal number of parameters! run as: sudo ./2-initial-setup.sh <username> <raspberryPiHostIp> [<ssh-public-key>]"
  exit(1)
fi

# SSH Setup
spawn ssh-copy-id -i $SSH_PUBLIC_KEY pi@$RPI_HOSTNAME
# spawn scp "$SSH_PUBLIC_KEY pi@$RPI_HOSTNAME:/tmp"
expect {
  -re ".*es.*o.*" {
    exp_send "yes\r"
    exp_continue
  }
  -re ".*password.*" {
    exp_send "raspberry\r"
  }
}
interact

# Setup new user
ssh pi@$RPI_HOSTNAME 'bash -s' < initial-user-setup.sh $USERNAME

# Setup security
ssh $USERNAME@$RPI_HOSTNAME 'bash -s' < initial-security-setup.sh $RPI_HOSTNAME

# Setup storage disks
ssh $USERNAME@$RPI_HOSTNAME 'bash -s' < initial-storage-setup.sh $USERNAME
