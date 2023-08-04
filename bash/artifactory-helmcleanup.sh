#!/bin/bash

curl -s -u "admin:${artifactory_pass}" -XPOST --data 'items.find({"repo":"helm-local","stat.downloaded":{"$before":"4mo"}})' -H"Content-Type: text/plain" https://jsnider-mtu.jfrog.io/artifactory/api/search/aql | jq '.results[] | "\(.path)/\(.name)"' | tr -d '"' > oldcharts.txt
if [[ $(wc -l oldcharts.txt | awk '{print $1}') -eq 0 ]]; then
    # Almost certainly an issue with the request; notify via slack for someone to investigate
    echo "AQL query resulted in 0 charts"
    curl -s -H"Content-Type: application/json" --data '{"channel": "#alerts", "attachments": [{"text": "Helm chart cleanup cronjob failed to find any old charts\nThis is almost definitely a failure, please investigate:", "fields": [], "actions": [], "color": "#ed5c5c"}], "username": "HelmCleanup", "icon_emoji": ":redx:"}' https://hooks.slack.com/services/aaaaaaaaa/aaaaaaaaa/aaaaaaaaaaaaaaaaaaaaaaaa
fi

SLACK_ALERTED=0
while read line; do
    echo "Deleting $line"
    STATUS=$(curl -s -u "admin:${artifactory_pass}" -XDELETE -w "%{http_code}\n" https://jsnider-mtu.jfrog.io/artifactory/helm-local/${line})
    echo $STATUS
    if [[ $STATUS != '204' ]]; then
        # Didn't delete; notify via slack for someone to investigate
        echo "Didn't delete the chart: $line"
        if [[ $SLACK_ALERTED -eq 0 ]]; then
            curl -s -H"Content-Type: application/json" --data '{"channel": "#alerts", "attachments": [{"text": "Helm cleanup cronjob failed to delete a chart\nPlease check datadog:", "fields": [], "actions": [{"type": "button", "text": "Visit datadog", "url": "https://app.datadoghq.com/logs?cols=core_host%2Ccore_service&live=true&messageDisplay=inline&stream_sort=desc&query=kube_namespace%3Ahelmcleanup-production"}], "color": "#ed5c5c"}], "username": "HelmCleanup", "icon_emoji": ":redx:"}' https://hooks.slack.com/services/aaaaaaaaa/aaaaaaaaa/aaaaaaaaaaaaaaaaaaaaaaaa
            SLACK_ALERTED=1
        fi
    fi
done < oldcharts.txt
