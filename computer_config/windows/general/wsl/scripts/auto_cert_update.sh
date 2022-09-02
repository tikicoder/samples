#!/bin/bash

mkdir -p /tmp/missing_certs

pushd /tmp/missing_certs

function find_ssl_ca(){
  cert_domain=$1
  cert_domain_file=$2
  openssl s_client -showcerts -verify 5 -connect "${cert_domain}:443" < /dev/null | awk -v awkcert="$cert_domain_file" '/BEGIN/,/END/{ if(/BEGIN/){a++}; out=""awkcert""a".pem"; print >out}'; 
}

find_ssl_ca "dl.k8s.io" "dl_k8s_io"
find_ssl_ca "ip.zscaler.com" "ip_zscaler_com"
find_ssl_ca "api.nuget.org" "api_nuget_org"
find_ssl_ca "update.code.visualstudio.com" "update_code_visualstudio_com"
find_ssl_ca "google.com" "google_com"
find_ssl_ca "raw.githubusercontent.com" "raw_githubusercontent_com"

missingcerts_user="$HOME/.local/missing_certs"
missingcerts_tmp="/tmp/missing_certs"
FILES="${missingcerts_tmp}/*"

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

if [ -z "$pem_path" ]; then
  echo "Could not determin pem save path"
  exit
fi

if [ -d "${missingcerts_user}" ]; then
 missingcerts_user_files="${missingcerts_user}/*"
  for f in $missingcerts_user_files
  do
    cp $f "${missingcerts_tmp}/$(basename $f)"
  done
fi


for f in $FILES
do
  echo "Processing $f file..."
  
  if [ $(openssl x509 -noout -text -in $f | grep --after-context=2 "X509v3 Basic Constraints" | grep -ic "CA:TRUE") -lt 1 ]; then
    sudo rm -f $f
    continue  
  fi
  
  echo ""
  echo ""
  openssl x509 -in $f -out "$f.pem" -outform PEM
  fingerprint=$(openssl x509 -in "$f.pem" -noout -fingerprint | awk -F'=' '{print $2}' | sed -e 's/:/_/g' )
  echo "$f is CA"
  echo "     $fingerprint"
  sudo mv -f "$f.pem" "$pem_path/$fingerprint.pem"
  sudo mv -f "$f" "$pem_path/$fingerprint-$(basename $f)"
  echo ""
  echo ""

done
sudo chown -R root:root $pem_path
sudo chmod -R 755 $pem_path

if [ $os_type == "rhel" ]; then
  sudo update-ca-trust
else
  sudo update-ca-certificates --fresh
fi
popd
sudo rm -Rf /tmp/missing_certs

adding_ca_path="${pem_path}/*"
python_ca_path=""
if [ ! -z "$(command -v python)" ]; then
  python_ca_path="$(python -m certifi)"
  echo "updating python path: $(python -m certifi)"
  sudo cat $adding_ca_path | sudo tee -a $(python -m certifi) > /dev/null
fi

if [ ! -z "$(command -v python3)" ]; then
  if [ "$python_ca_path" != "$(python3 -m certifi)" ]; then
    echo "updating python path: $(python3 -m certifi)"
    sudo cat $adding_ca_path | sudo tee -a $(python3 -m certifi) > /dev/null
  fi
fi
