#!/bin/bash

mkdir -p /tmp/custom_certs_add

pushd /tmp/custom_certs_add

openssl s_client -showcerts -verify 5 -connect ip.zscaler.com:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done
openssl s_client -showcerts -verify 5 -connect update.code.visualstudio.com:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done

FILES="/tmp/custom_certs_add/*"

pem_path=""
os_type=""
if [ -f "/etc/redhat-release" ]; then
  pem_path="/etc/pki/ca-trust/source/anchors"
  os_type="rhel"
elif [ $(grep -ic "^ID=ubuntu$" /etc/os-release ) -gt 0 ]; then
  pem_path="/usr/local/share/ca-certificates"
  os_type="ubuntu"
else
  pem_path=""
fi

if [ -z "$pem_path"]; then
  echo "Could not determin pem save path"
  exit
fi
for f in $FILES
do
  echo "Processing $f file..."
  
  if [ $(openssl x509 -noout -text -in $f | grep --after-context=2 "X509v3 Basic Constraints" | grep -ic "CA:TRUE") -gt 0 ]; then
    openssl x509 -in $f -out "$f.pem" -outform PEM
    fingerprint=$(openssl x509 -in "$f.pem" -noout -fingerprint | awk -F'=' '{print $2}' | sed -e 's/:/_/g' )
    echo "$f is CA"
    echo "     $fingerprint"
    sudo mv -f "$f.pem" "$pem_path/$fingerprint.pem"
  fi

done

if [ $os_type == "rhel" ]; then
  sudo update-ca-trust
else
  update-ca-certificates --fresh
fi
popd
rm -Rf /tmp/custom_certs_add