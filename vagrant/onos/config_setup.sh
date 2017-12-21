#!/bin/bash

#############
## Locale. ##
#############
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8

####################
## Configure ONOS ##
####################
printf "\n### Configure ONOS ###"
cp buck-out/gen/tools/package/onos-package/onos.tar.gz /opt/
tar -xzf /opt/onos.tar.gz -C /opt/
mv /opt/onos-1.12.1-SNAPSHOT/ /opt/onos/
chown -cR ubuntu /opt/onos/
echo "export ONOS_APPS=drivers,openflow-base,hostprovider,netcfglinksprovider,ifwd,proxyarp,mobility" >> /home/ubuntu/.profile

###########################
## Adding public SSH key ##
###########################
printf "\n### Copy public SSH key ###"
if [ -f /home/ubuntu/.ssh/me.pub ]; then
  cat /home/ubuntu/.ssh/me.pub >> /home/ubuntu/.ssh/authorized_keys
  if [ -f /opt/onos/apache-karaf-3.0.8/etc/keys.properties ]; then
    printf "karaf=" >> /opt/onos/apache-karaf-3.0.8/etc/keys.properties
    # get only the key
    cat /home/ubuntu/.ssh/me.pub | cut -d ' ' -f 2 | tr -d '\n' >> /opt/onos/apache-karaf-3.0.8/etc/keys.properties
    printf ",_g_:admingroup\n" >> /opt/onos/apache-karaf-3.0.8/etc/keys.properties
  else
    printf "No apache-karaf folder found inside ONOS!\n"
  fi
  rm /home/ubuntu/.ssh/me.pub
else
  printf "No public SSH key available! No connection via SSH possible without password!\n" 1>&2
fi

###########################
## Make files executable ##
###########################
if [ -f /vagrant/onosLoad.sh ]; then
  chmod +x /vagrant/onosLoad.sh
fi
