#!/bin/sh
set -e
O=/data/options.json
export Nemlig__Username="$(jq -r '.nemlig_username' $O)"
export Nemlig__Password="$(jq -r '.nemlig_password' $O)"
export MQTT__Server="$(jq -r '.mqtt_server' $O)"
export MQTT__Port="$(jq -r '.mqtt_port' $O)"
export MQTT__Username="$(jq -r '.mqtt_username' $O)"
export MQTT__Password="$(jq -r '.mqtt_password' $O)"
cd /app
exec dotnet ./MBW.Nemlig2MQTT.dll
