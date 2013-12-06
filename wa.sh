#!/bin/bash
#
# by Sairon Istyar, 2012
# distributed under the GPLv3 license
# http://www.opensource.org/licenses/gpl-3.0.html
#

[ -f ~/.wolfram_api_key ] && . ~/.wolfram_api_key

# properly encode query
q=$(echo ${*} | sed 's/+/%2B/g' | tr '\ ' '\+')

# fetch and parse result
result=$(curl -s "http://api.wolframalpha.com/v2/query?input=${q}&appid=${API_KEY}&format=plaintext")

if [ -n "$(echo ${result} | grep 'Invalid appid')" ] ; then
	echo "Invalid API key!"
	echo "Get one at https://developer.wolframalpha.com/portal/apisignup.html"
	echo -n 'Enter your WolframAlpha API key:'
	read api_key
	echo "API_KEY=${api_key}" >> ~/.wolfram_api_key
	exit 1
fi

result=`echo "${result}" \
	| tr '\n' '\t' \
	| sed -e 's/<plaintext>/\'$'\n<plaintext>/g' \
	| grep -oE "<plaintext>.*</plaintext>|<pod title=.[^\']*" \
	| sed 's!<plaintext>!!g; \
		s!</plaintext>!!g; \
		s!<pod title=.*!\\\x1b[1;36m&\\\x1b[0m!g; \
		s!<pod title=.!!g; \
		s!\&amp;!\&!' \
	| tr '\t' '\n' \
	| sed  '/^$/d; \
		s/\ \ */\ /g'`


# print result
echo -e "${result}"
