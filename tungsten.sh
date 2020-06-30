#!/bin/bash

#
# Copyright 2012 Sairon Istyar
# Copyright 2013-2020 Alex Szczuczko
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Setup
#

set -euo pipefail

error () {
    echo "$@" >&2
}

#
# Load stored API key
#

key_path="$HOME/.wolfram_api_key"
key_pattern='[A-Z0-9]{6}-[A-Z0-9]{10}'

if ! [ -v WOLFRAM_API_KEY ]
then
    if [ -f "$key_path" ]
    then
        # Load the contents of $key_path file as WOLFRAM_API_KEY
        WOLFRAM_API_KEY="$(<"$key_path")"
        if ! [[ "$WOLFRAM_API_KEY" =~ $key_pattern ]]
        then
            error "WolframAlpha API key read from file '$key_path' doesn't match the validation pattern"
            exit 2
        fi

    elif [ -e "$key_path" ]
    then
        error "WolframAlpha API key path '$key_path' exists, but isn't a file."
        exit 3

    else
        WOLFRAM_API_KEY=""
    fi
fi

#
# Read the query
#

query="${@:-}"

if [ -z "$query" ]
then
    error "You must specify a query to make"
    exit 5
fi

#
# Perform the query
#
curl_args=(
    -sSf -G
    --data-urlencode "output=JSON"
    --data-urlencode "format=plaintext"
    --data-urlencode "input=$query"
)
if [ -n "$WOLFRAM_API_KEY" ]
then
    curl_args+=(
        --data-urlencode "appid=$WOLFRAM_API_KEY"
        "https://api.wolframalpha.com/v2/query"
    )
    iconv_from="UTF-8"
else
    error "Querying without an API key. There may be incorrect / missing characters."
    error "To query with an API key, add the key to $key_path as described in the README"
    curl_args+=(
        --data-urlencode "type=full"
        -e "https://products.wolframalpha.com/api/explorer/"
        "https://www.wolframalpha.com/input/apiExplorer.jsp"
    )
    iconv_from="ISO-8859-1"
fi
result="$(curl "${curl_args[@]}" | iconv -f "$iconv_from" -t UTF-8)"

#
# Process the result of the query
#

query_result () {
    set -euo pipefail
    jq -r "$1" <<<"$result"
}

# Handle error results
if [ "$(query_result '.queryresult.error')" != "false" ]
then
    error_msg="$(query_result '.queryresult.error.msg')"

    if [ "$error_msg" = "Invalid appid" ]
    then
        error "WolframAlpha API rejected the given API key"
        error "Modify or remove the key stored in file '$key_path'"
        exit 6
    else
        error "WolframAlpha API returned an error: $error_msg"
        exit 7
    fi
fi

# Only colourise if stdout is a terminal
if [ -t 1 ]
then
    titleformat='\e[1;34m%s\e[m\n'
else
    titleformat='%s\n'
fi

# Print title+plaintext for each pod with text in it's subpod/plaintext child
while read -r title
do
    printf "$titleformat" "$title"

    # Process the >0 plaintext elements decendent of the current pod
    query_result ".queryresult.pods[] | select(.title == \"$title\") | .subpods[].plaintext"
done < <(query_result '.queryresult.pods[] | select(.subpods[0].plaintext != "") | .title')
