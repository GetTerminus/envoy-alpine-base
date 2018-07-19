#!/bin/sh -eu

ca_cert_dir=/usr/local/share/ca-certificates
ca_cert_name=ca-cert-Envoy_Root_CA

cert_dir=/etc/ssl/certs
cert_name=envoy_wildcard

cert_config_dir=/etc/envoy

# generate key for CA
openssl genrsa -out ${ca_cert_dir}/${ca_cert_name}.key 4096

# generate the actual CA cert
openssl req -x509 \
  -new \
  -nodes \
  -key ${ca_cert_dir}/${ca_cert_name}.key \
  -sha256 \
  -days 30 \
  -config ${cert_config_dir}/cert.conf \
  -out ${ca_cert_dir}/${ca_cert_name}.pem

# update CA certs to register previously created cert with the OS
update-ca-certificates

# generate key for wildcard cert
openssl genrsa -out ${cert_dir}/${cert_name}.key 4096

# generate CSR for the cert
openssl req -new \
  -key ${cert_dir}/${cert_name}.key \
  -config ${cert_config_dir}/cert.conf \
  -out ${cert_name}.csr

# create and sign a cert with our CA
openssl x509 -req \
  -in ${cert_name}.csr \
  -CA ${ca_cert_dir}/${ca_cert_name}.pem \
  -CAkey ${ca_cert_dir}/${ca_cert_name}.key \
  -CAcreateserial \
  -out ${cert_dir}/${cert_name}.pem \
  -days 30 \
  -sha256 \
  -extfile ${cert_config_dir}/cert.ext
