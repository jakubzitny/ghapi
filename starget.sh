#!/bin/bash

ghtoken="$2"
dataid="$1"

prefix=res

list=data/"$1"

getRepoJson() {
	curl --silent "$1?access_token=$ghtoken" -H 'Accept: application/vnd.github.preview' 2> /dev/null
}

processUrl() {
	url="$2"
	id="$1"
	repojson=`getRepoJson $url`
	stargazers_fields_count=`echo "$repojson" | grep 'stargazers_count' | wc -l`
	redirect=`echo "$repojson" | grep '"message": "Moved Permanently"'`
	notfound=`echo "$repojson" | grep '"message": "Not Found"'`
	limit=`echo "$repojson" | grep '"message": "API rate limit'`
	if [ "$limit" ]; then
		reset=`curl --silent "https://api.github.com/rate_limit?access_token=$ghtoken" -H 'Accept: application/vnd.github.preview' | jq '.resources.core.reset'`
		now=`date +%s`
		toSleep=`echo $((reset-now+60))`
		sleep $toSleep
		processUrl $id $url
	elif [ "$redirect" ]; then
		redirectUrl=`echo "$repojson" | jq '.url' | sed 's/\"//g' | cut -d"?" -f1`
		processUrl $id $redirectUrl
		echo $id,$url "--" REDIRECT >> $prefix/redirects_$dataid.txt
	elif [ "$notfound" ]; then
		echo $id,$url "--" NOTFOUND >> $prefix/notfounds_$dataid.txt
	elif [ "$stargazers_fields_count" -gt "1" ]; then
		echo $id,$url "--" MULTIPLE $stargazers_fields_count >> $prefix/multiples_$dataid.txt
	else
		stars=`echo "$repojson" | jq '.stargazers_count'`
		forks=`echo "$repojson" | jq '.forks_count'`
		subscribers=`echo "$repojson" | jq '.subscribers_count'`
		created=`echo "$repojson" | jq '.created_at'`
		updated=`echo "$repojson" | jq '.updated_at'`
		pushed=`echo "$repojson" | jq '.pushed_at'`
		echo $id,$stars,$forks,$subscribers,$created,$updated,$pushed
		echo $id,$stars,$forks,$subscribers,$created,$updated,$pushed >> $prefix/stats_$dataid.csv
	fi
}

while IFS=',' read -r id url
do
	processUrl $id $url
done < "$list"
