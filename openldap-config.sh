#!/bin/bash

# init
function pause(){
   read -p "$*"
}
NOW=$(date +"%Y%m%d%H%M")
ldappassword="/tmp/ldap/password.txt"
echo "Enter the name of the domain : "
read domain
echo "Enter the username you want created (use domain name)"
read usr
echo "Enter the Password "
read password

slappasswd -h {SSHA} -s $password > $ldappassword

cat "$ldappassword" >> "$ldappassword"

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
olcRootDN: $user
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $ldappassword2 "
 > /tmp/ldap/db2.ldif


echo "


dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="$user,$domain,$name" read by * none"

> /tmp/ldap/monitor.ldif


ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*


ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo " 

dn: dc=domain,dc=local
dc: domain
objectClass: top
objectClass: domain

dn: cn=ldapadmin,dc=domain,dc=local
objectClass: organizationalRole
cn: ldapadmin
description: LDAP Manager

dn: ou=People,dc=domain,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=domain,dc=local
objectClass: organizationalUnit
ou: Group "
> /tmp/ldap/base.ldif


ldapadd -x -W -D "$user,$domain,$name" -f base.ldif


