#!/bin/bash

# init
function pause(){
   read -p "$*"
}
NOW=$(date +"%Y%m%d%H%M")
echo "Enter the name of the domain : "
read domain
echo "Enter the domain extention : "
read name
echo "Enter the username you want created (use domain name)"
read user
echo "Enter the Password "
read password


cd /tmp
mkdir /tmp/ldap
cd /tmp/ldap

echo "
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $domain
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=$user,dc=$domain,dc=$name
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $password"   > /tmp/ldap/db3.ldif
  

echo "
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=$user,dc=$domain,dc=$name" read by * none" > /tmp/ldap/monitor3.ldif


ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*


ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo " 

dn: dc=$domain,dc=$name
dc: $domain
objectClass: top
objectClass: domain

dn: cn=$user,dc=$domain,dc=$name
objectClass: organizationalRole
cn: $user
description: LDAP Manager

dn: ou=People,dc=$domain,dc=$name
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=$domain,dc=$name
objectClass: organizationalUnit
ou: Group " /tmp/ldap/base3.ldif


ldapadd -x -W -D "cn=$user,dc=$domain,dc=$name" -f base.ldif


