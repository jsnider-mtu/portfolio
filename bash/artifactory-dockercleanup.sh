#!/bin/bash

kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | grep jsnider-mtu-docker | sort | uniq | sed 's#^jsnider-mtu-docker.jfrog.io/##;s#:#/#' > current-images.txt

curl -s -u "admin:${artifactory_pass}" -XPOST --data 'items.find({"name":{"$eq":"manifest.json"},"stat.downloaded":{"$before":"1mo"}})' -H"Content-Type: text/plain" https://jsnider-mtu.jfrog.io/artifactory/api/search/aql | jq '.results[].path' | cut -d'"' -f2 > oldimages.txt
if [[ $(wc -l oldimages.txt | awk '{print $1}') -eq 0 ]]; then
  # Almost certainly an issue with the request; notify via slack for someone to investigate
  echo "AQL query resulted in 0 images"
  curl -s -H"Content-Type: application/json" --data '{"channel": "#alerts", "attachments": [{"text": "Docker cleanup cronjob failed to find any old images\nThis is almost definitely a failure, please investigate", "fields": [], "actions": [], "color": "#ed5c5c"}], "username": "DockerCleanup", "icon_emoji": ":redx:"}' https://hooks.slack.com/services/aaaaaaaaaaa/aaaaaaaaaaa/aaaaaaaaaaaaaaaaaaaaaaaa
fi

while read line; do
  sed -i "\#$line#d" oldimages.txt
done < current-images.txt

SLACK_ALERTED=0
while read line; do
  echo "Deleting $line"
  STATUS=$(curl -s -u "admin:${artifactory_pass}" -XDELETE -w "%{http_code}\n" https://jsnider-mtu.jfrog.io/artifactory/docker-local/${line})
  echo $STATUS
  if [[ $STATUS != '204' ]]; then
    # Didn't delete; notify via slack for someone to investigate
    echo "Didn't delete the image: $line"
    if [[ $SLACK_ALERTED -eq 0 ]]; then
      curl -s -H"Content-Type: application/json" --data '{"channel": "#alerts", "attachments": [{"text": "Docker cleanup cronjob failed to delete an image\nPlease check datadog:", "fields": [], "actions": [{"type": "button", "text": "Visit datadog", "url": "https://app.datadoghq.com/logs?cols=core_host%2Ccore_service&live=true&messageDisplay=inline&stream_sort=desc&query=kube_namespace%3Adockercleanup-production"}], "color": "#ed5c5c"}], "username": "DockerCleanup", "icon_emoji": ":redx:"}' https://hooks.slack.com/services/aaaaaaaaaaa/aaaaaaaaaaa/aaaaaaaaaaaaaaaaaaaaaaaa
      SLACK_ALERTED=1
    fi
  fi
done < oldimages.txt
