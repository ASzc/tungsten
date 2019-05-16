#!/bin/bash

#
# Copyright 2012 Sairon Istyar
# Copyright 2013-2017 Alex Szczuczko
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

# Stop if an error is encountered
set -e
# Stop if an undefined variable is referenced
set -u

error () {
    echo "$@" >&2
}

#
# Load stored API key
#

key_path="$HOME/.wolfram_api_key"
key_pattern='[A-Z0-9]{6}-[A-Z0-9]{10}'

if [ -f "$key_path" ]
then
    # Load the contents of $key_path file as API_KEY
    API_KEY="$(<"$key_path")"
    if ! [[ "$API_KEY" =~ $key_pattern ]]
    then
        error "WolframAlpha API key read from file '$key_path' doesn't match the validation pattern"
        exit 2
    fi

elif [ -e "$key_path" ]
then
    error "WolframAlpha API key path '$key_path' exists, but isn't a file."
    exit 3

else
    # Only prompt if interacting with a terminal directly
    # stdin and stderr count, we aren't using stdout for the prompt here
    if [ -t 0 ] && [ -t 2 ]
    then
        error "Cannot query without a WolframAlpha API key"
        error "Get one at https://developer.wolframalpha.com/portal/apisignup.html"
        error "It can take a few minutes or hours to recieve your key"

        API_KEY=""
        while ! [[ "$API_KEY" =~ $key_pattern ]]
        do
            read -r -p "Enter an API key in the form '$key_pattern': " API_KEY
        done

        echo "$API_KEY" > "$key_path"
        error "Key stored in '$key_path' for future use"
        error ""

    else
        error "Cannot query without a WolframAlpha API key. Write the key to '$key_path'"
        exit 4
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

result="$(curl -sS -G --data-urlencode "appid=$API_KEY" \
                      --data-urlencode "format=plaintext" \
                      --data-urlencode "input=$query" \
                      "https://api.wolframalpha.com/v2/query")"

#
# Process the result of the query
#

xpath_value () {
    echo "$result" | \
    xmlstarlet sel -t -v "$1" -n - | \
    xmlstarlet unesc - | \
    sed -E 's/+/=/g'
}

# Handle error results
if [ "$(xpath_value '/queryresult/@error')" = "true" ]
then
    error_msg="$(xpath_value '/queryresult/error/msg')"

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
xpath_value '/queryresult/pod[subpod/plaintext/text()]/@title' | \
while read -r title
do
    printf "$titleformat" "$title"

    # Process the >0 plaintext elements decendent of the current pod
    xpath_value "/queryresult/pod[@title='$title']/subpod/plaintext"
done
