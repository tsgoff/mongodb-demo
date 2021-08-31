#!/bin/bash -xe
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/sbin:/bin"

cat <<EOF > /etc/profile.d/firstboot_vars.sh
export EC2_HOSTNAME=${hostname}
export EC2_DOMAIN=${domain}
export EC2_FQDN=${hostname}.${domain}
export EC2_Environment=${Environment}
export EC2_App=${App}
export EC2_Project=${Project}

export HISTTIMEFORMAT="%F %T  "
export HISTSIZE=3000
export HISTFILESIZE=40000
alias ll='ls -lah --color=auto'

EOF
. /etc/profile.d/firstboot_vars.sh

# sethostname
echo $EC2_FQDN > /etc/hostname && hostname $EC2_FQDN

# create demo user
useradd -s /bin/bash -m demo
mkdir /home/demo/.ssh/
cat /home/ubuntu/.ssh/authorized_keys > /home/demo/.ssh/authorized_keys
chmod 0600 /home/demo/.ssh/authorized_keys && chown demo:demo /home/demo/.ssh/authorized_keys

cat <<EOF > /etc/sudoers.d/demo
demo ALL=(ALL) NOPASSWD:ALL

EOF

# set hostname

echo "${hostname}.${domain}" > /etc/hostname
hostnamectl set-hostname "${hostname}.${domain}"


echo "set mouse-=a" > ~/.vimrc

# aws
apt update && apt -y install unzip jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -f awscliv2.zip

# add key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B00A0BD1E2C63C11

# prepare xfs data volume
mkdir -p /data
EBS2=`lsblk -l | grep disk | awk '{print $1}' | sort -n | tail -n1`
sleep 1
mkfs.xfs -f /dev/$EBS2
sleep 1
echo "UUID=`lsblk -no UUID /dev/\$EBS2` /data xfs defaults 0 0" >> /etc/fstab
mount -a

# puppet
echo ${Environment} > /etc/puppet_env
echo ${App} | cut -d '-' -f 2 > /etc/puppet_app
echo ${Project} > /etc/puppet_project
cd /tmp && wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
dpkg -i puppet6-release-bionic.deb
apt update && apt -y install puppet
rm -f /etc/puppet/hiera.yaml
mkdir -p /etc/puppet/hiera
echo "version: 5
hierarchy:
  - name: app
    path: app.yaml

defaults:
  data_hash: yaml_data
  datadir: /etc/puppet/hiera" > /etc/puppet/hiera.yaml

#codedeploy agent
cd /tmp && wget https://aws-codedeploy-eu-west-1.s3.amazonaws.com/latest/install && chmod +x ./install && ./install auto && /etc/init.d/codedeploy-agent start





