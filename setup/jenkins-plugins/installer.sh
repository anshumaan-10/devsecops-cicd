#!/bin/bash

set -eo pipefail

JENKINS_URL='http://localhost:8080'
JENKINS_USER='admin'
JENKINS_PASSWORD='admin'

# Fetch Jenkins crumb
JENKINS_CRUMB_JSON=$(curl -s --cookie-jar /tmp/cookies -u $JENKINS_USER:$JENKINS_PASSWORD ${JENKINS_URL}/crumbIssuer/api/json)

# Debug: Check if crumb JSON is valid
if [[ -z "$JENKINS_CRUMB_JSON" ]]; then
  echo "Error: Failed to fetch Jenkins crumb."
  exit 1
fi

echo "Crumb JSON Response: $JENKINS_CRUMB_JSON"

# Extract crumb value
JENKINS_CRUMB=$(echo "$JENKINS_CRUMB_JSON" | jq .crumb -r)

if [[ -z "$JENKINS_CRUMB" ]]; then
  echo "Error: Failed to extract crumb value."
  exit 1
fi

# Fetch Jenkins API token
JENKINS_TOKEN_JSON=$(curl -s -X POST -H "Jenkins-Crumb:${JENKINS_CRUMB}" --cookie /tmp/cookies "${JENKINS_URL}/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken?newTokenName=demo-token66" -u $JENKINS_USER:$JENKINS_PASSWORD)

# Debug: Check if token JSON is valid
if [[ -z "$JENKINS_TOKEN_JSON" ]]; then
  echo "Error: Failed to fetch Jenkins token."
  exit 1
fi

echo "Token JSON Response: $JENKINS_TOKEN_JSON"

# Extract the token value
JENKINS_TOKEN=$(echo "$JENKINS_TOKEN_JSON" | jq .data.tokenValue -r)

if [[ -z "$JENKINS_TOKEN" || "$JENKINS_TOKEN" == "null" ]]; then
  echo "Error: Failed to extract Jenkins token."
  exit 1
fi

# Print Jenkins URL, Crumb, and Token for verification
echo "Jenkins URL: $JENKINS_URL"
echo "Jenkins Crumb: $JENKINS_CRUMB"
echo "Jenkins Token: $JENKINS_TOKEN"

# Install plugins listed in plugins.txt
if [[ ! -f plugins.txt ]]; then
  echo "Error: plugins.txt not found."
  exit 1
fi

while read plugin; do
  if [[ -n "$plugin" ]]; then
    echo "........Installing ${plugin} .."
    curl -s -X POST --data "<jenkins><install plugin='${plugin}' /></jenkins>" \
      -H 'Content-Type: text/xml' "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
      --user "$JENKINS_USER:$JENKINS_TOKEN" -H "Jenkins-Crumb:${JENKINS_CRUMB}"
  fi
done < plugins.txt

# Optionally restart Jenkins if needed
# curl -X POST "$JENKINS_URL/safeRestart" --user "$JENKINS_USER:$JENKINS_TOKEN" -H "Jenkins-Crumb:${JENKINS_CRUMB}"

# Check all installed plugins
# Jenkins.instance.pluginManager.plugins.each { plugin -> println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}") }

# Check for updates/errors
# http://<jenkins-url>/updateCenter
