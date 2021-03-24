#!/bin/sh

do_patch_root_login()
{
    # 
    sed -i 's/.*PermitRootLogin.*/#PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
}

do_patch_resolved()
{
    # 
    > /etc/systemd/resolved.conf
    echo "#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details

[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#DNSOverTLS=no
#Cache=no-negative
#DNSStubListener=yes
#ReadEtcHosts=yes" >> /etc/systemd/resolved.conf
}