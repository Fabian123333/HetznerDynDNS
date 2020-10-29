#!/bin/bash

#DNS_ID='123456789abcdef'
#RECORDS='@,www'
#API_TOKEN="123456789abcdef"

API_URL="https://dns.hetzner.com/api/v1/"

if [ -z "${IP_SERVICE}" ]; then
	IP_SERVICE="https://ifconfig.me/ip";
fi

if [ -z "${INTERVAL}" ]; then
	INTERVAL="60s";
fi

if [ -z "${TTL}" ]; then
	TTL="60";
fi

api_token="$(cat /run/secrets/api-token || echo $API_TOKEN)"

getIdByName(){
	record="$1"
	zonefile="$2"

	echo "$zonefile" | jq '.records[] | {id: .id, name: .name, type: .type, value: .value}'  | 
		tr -d '"' | tr -d ',' | tr -d ':' | 
		awk '
		    $1 == "id" {id=$2}
			$1 == "name" {name=$2}
			$1 == "type" && $2 == "A" && name == "'${record}'" {print id}'
}

getValueById(){
	id="$1"
	zonefile="$2"

	echo "$zonefile" | jq '.records[] | {id: .id, value: .value}' 2>/dev/null | 
		tr -d '"' | tr -d ',' | tr -d ':' |
		awk '
			$1 == "id" {id=$2}
			$1 == "value" && id == "'${id}'" { print $2 }'
}

getZonefile(){
	curl -s ${API_URL}records?zone_id=${DNS_ID} -H 'Auth-API-Token: '${api_token}
}

echo "fetch dns zonefile..."
zonefile="$(getZonefile)"

while true; do
	echo "check current ip from ${IP_SERVICE}..."
	ext_ip="$(curl -sL ${IP_SERVICE})"
	echo "detect external ip: ${ext_ip}"	

	if [ -n "${ext_ip}" ]; then
		echo $RECORDS | tr "," "\n" | while read host; do
			echo "check record ${host}..."
			record_ids=`getIdByName "${host}" "${zonefile}"`
			echo "detect record ids: '${record_ids}'"
			if [ "${record_ids}" == "" ]; then
				echo "create record ${host} with ${ext_ip}"
				curl -sX "POST" "${API_URL}records" \
					-H 'Content-Type: application/json' \
					-H 'Auth-API-Token: '${api_token} \
					-d $'{
						"value": "'${ext_ip}'",
						"ttl": '${TTL}',
						"type": "A",
						"name": "'${host}'",
						"zone_id": "'$DNS_ID'"
					}';
				echo "fetch dns zonefile..."
				zonefile="$(getZonefile)"
			else
				for id in ${record_ids}; do
					dns_ip=`getValueById "${id}" "${zonefile}"`
					echo "detect current value: ${dns_ip}"

					if [ "${dns_ip}" != "${ext_ip}" ]; then
						echo "update record ${host} with ${ext_ip}"

						curl -sX "PUT" "https://dns.hetzner.com/api/v1/records/"${id} \
						-H 'Content-Type: application/json' \
						-H 'Auth-API-Token: '${api_token} \
						-d $'{
							"value": "'${ext_ip}'",
							"ttl": '${TTL}',
							"type": "A",
							"name": "'${host}'",
							"zone_id": "'$DNS_ID'"
						}';
						echo "fetch dns zonefile..."
						zonefile="$(getZonefile)"
					fi;
				done;
			fi;
		done
	fi;

	sleep "${INTERVAL}"
done
