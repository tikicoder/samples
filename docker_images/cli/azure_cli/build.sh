#!/bin/bash

if [ ! $(command -v "realpath") ]; then
    realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
    }
fi

base_dir="$(dirname $(realpath $0))"

function process_base_files() {
    for f in $1
    do
    
    echo "Processing $f file..."
    
    if [ $(openssl x509 -noout -text -in $f | grep --after-context=2 "X509v3 Basic Constraints" | grep -ic "CA:TRUE") -lt 1 ]; then
        rm -f $f
        continue 
    fi

    openssl x509 -in $f -out "$f.pem" -outform PEM
    fingerprint=$(openssl x509 -in "$f.pem" -noout -fingerprint | awk -F'=' '{print $2}' | sed -e 's/:/_/g' )
    mv -f "$f.pem" "$fingerprint.pem"


    done
}

pushd "${base_dir}/ca_certs"
mkdir -p "private"
mkdir -p "public"

pushd "${base_dir}/ca_certs/public"
process_base_files "${base_dir}/ca_certs/public/*"
popd
pushd "${base_dir}/ca_certs/private"
process_base_files "${base_dir}/ca_certs/private/*"
popd

mkdir -p "custom"
pushd custom

openssl s_client -showcerts -verify 5 -connect ip.zscaler.com:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done
openssl s_client -showcerts -verify 5 -connect update.code.visualstudio.com:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done
openssl s_client -showcerts -verify 5 -connect google.com:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done
openssl s_client -showcerts -verify 5 -connect raw.githubusercontent.co:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'; for cert in *.pem; do newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; echo "${newname}"; mv "${cert}" "${newname}"; done


FILES="${base_dir}/ca_certs/custom/*"

for f in $FILES
do
  echo "Processing $f file..."
  
  if [ $(openssl x509 -noout -text -in $f | grep --after-context=2 "X509v3 Basic Constraints" | grep -ic "CA:TRUE") -lt 1 ]; then
    rm -f $f
    continue 
  fi

  openssl x509 -in $f -out "$f.pem" -outform PEM
  fingerprint=$(openssl x509 -in "$f.pem" -noout -fingerprint | awk -F'=' '{print $2}' | sed -e 's/:/_/g' )
  mv -f "$f.pem" "../private/$fingerprint.pem"


done


popd
rm -Rf custom

popd

docker build -t tiki/azure_cli $base_dir