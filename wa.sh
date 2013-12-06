#!/bin/bash

#
# Copyright 2012 Sairon Istyar
# Copyright 2013 Alex Szczuczko
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
    # Only prompt if the shell is interactive
    if [ -v PS1 ]
    then
        error "Cannot query without a WolframAlpha API key"
        error "Get one at https://developer.wolframalpha.com/portal/apisignup.html"

        API_KEY=""
        while ! [[ "$API_KEY" =~ $key_pattern ]]
        do
            read -r -p "Enter an API key in the form '$key_pattern': " API_KEY
        done

        echo "$API_KEY" > "$key_path"
        error "Key stored in '$key_path' for future use"

    else
        error "Cannot query without a WolframAlpha API key. Write the key to '$key_path'"
        exit 4
    fi
fi

#
# Read the query
#

query="${@?You must specify a query to make}"

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

if [[ "$result" =~ Invalid appid ]]
then
    error "WolframAlpha API has rejected the given API key"
    error "Modify or remove the key stored in file '$key_path'"
    exit 5
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
