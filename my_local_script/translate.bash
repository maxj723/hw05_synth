#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <tcsh_script_file>"
  exit 1
fi

tcsh_script_file=$1

prepend() {
  if [ -d "$2" ]; then
    if [[ ":$1:" != *":$2:"* ]]; then
      export "$1=$2:${!1}"
    fi
  fi
}

extend() {
  if [ -d "$2" ]; then
    if [[ ":$1:" != *":$2:"* ]]; then
      export "$1=${!1}:$2"
    fi
  fi
}

while IFS= read -r line; do
  line=$(echo "$line" | sed 's/^\s*//') # Remove leading whitespace

  if [[ $line =~ ^# ]]; then
    continue # Skip comments
  elif [[ $line =~ ^alias[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
    alias_name=${BASH_REMATCH[1]}
    alias_definition=${BASH_REMATCH[2]}
    alias "$alias_name"="$alias_definition"
  elif [[ $line =~ ^set[[:space:]]+([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    value=$(echo "$value" | sed 's/^"//; s/"$//')  # Remove surrounding quotes
    value=$(echo "$value" | sed "s/\\\!/\!/g")  # Remove escaping of '!' character
    export "$variable=$value"
  elif [[ $line =~ ^setenv[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    value=$(echo "$value" | sed "s/\\\!/\!/g")  # Remove escaping of '!' character
    export "$variable=$value"
  elif [[ $line =~ ^prepend[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    prepend "$variable" "$value"
  elif [[ $line =~ ^extend[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    extend "$variable" "$value"
  else
    eval "$line"
  fi
done < "$tcsh_script_file"
