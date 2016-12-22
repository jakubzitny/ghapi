#!/bin/bash

ghtoken="$2"
dataid="$1"

prefix=res

list=data/"$1"


getCommitResponse() {
	curl -ni "$1/commits?access_token$ghtoken" -H 'Accept: application/vnd.github.preview' 2> /dev/null
}

processUrl() {
	url="$2"
	id="$1"
	commitresponse=`getCommitResponse $url`
	commitPages=
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
		commitPages=`echo "$commitresponse" | head -26 | awk -F"=" '/Link:/{print $4}' | sed 's/\>.*$//g'`
		commitCount=`echo $((commitPages*30))`
		lastCommitDate=`echo "$commitresponse" | tail -n +27 | jq '.[1].commit.author.date'`
		echo $id,$commitPages,$commitCount
		echo $id,$commitPages,$commitCount >> $prefix/commits_$dataid.csv
	fi
}

while IFS=',' read -r id url
do
	processUrl $id $url
done < "$list"
