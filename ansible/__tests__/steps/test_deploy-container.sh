#!/bin/bash
# IP address in environment "IP"
# Domain in environment "DOMAIN"
INVENTORY_PATH=ansible/__tests__/inventory.yml

# This test deploys a container project onto the target server
# IMPORTANT: This must run after test_provision.sh!

function http_check() {
  echo "Checking HTTP content on ${1}"
  if [[ "${3}" != "" && "${4}" != "" ]]; then
    CONTENT=$(wget --no-check-certificate --https-only --http-user="${3}" --http-password="${4}" -q -O - "${1}")
  else
    CONTENT=$(wget --no-check-certificate --https-only -q -O - "${1}")
  fi
  if [[ $CONTENT != *"${2}"* ]]; then
    echo "HTTP content check failed: ${CONTENT}" 1>&2
    exit 1
  else
    echo "HTTP content check succeeded"
  fi
}

sed -e "s/\${ipaddress}/${IP}/" -e "s/\${webserver}/${WEBSERVER}/" -e "s/\${application}/container/" ansible/__tests__/inventory.dist.yml > ansible/__tests__/inventory.yml
sed -e "s/\${domain}/${DOMAIN}/" ansible/__tests__/projects/container.dist.yml > ansible/__tests__/projects/container.yml
TEST=1 ansible-playbook ansible/application-deploy.yml -i $INVENTORY_PATH -vv

# wait some time for server to finish
sleep 5s

http_check "https://${DOMAIN}" "Hello world!"
http_check "https://${DOMAIN}:81" "phpMyAdmin"
http_check "https://sub.${DOMAIN}" "phpMyAdmin" "user" "pass"

TEST=1 ansible-playbook ansible/application-destroy.yml -i $INVENTORY_PATH --extra-vars "project_name=container" -vv