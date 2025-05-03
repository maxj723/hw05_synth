#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <tcsh_script_file>"
  exit 1
fi

tcsh_script_file=$1

echo "Debugging: tcsh_script_file=$tcsh_script_file"

prepend() {
  echo "Debugging: prepend() called with args: $1, $2"
  if [ -d "$2" ]; then
    echo "Debugging: Directory $2 exists"
    if [[ ":$1:" != *":$2:"* ]]; then
      echo "Debugging: Prepending $2 to $1"
      eval "$1=$2:\${$1}"
      export "$1"
      echo "Debugging: $1 is now ${!1}"
    else
      echo "Debugging: $2 already exists in $1"
    fi
  else
    echo "Debugging: Directory $2 does not exist"
  fi
}

extend() {
  echo "Debugging: extend() called with args: $1, $2"
  if [ -d "$2" ]; then
    echo "Debugging: Directory $2 exists"
    if [[ ":$1:" != *":$2:"* ]]; then
      echo "Debugging: Extending $1 with $2"
      eval "$1=\${$1}:$2"
      export "$1"
      echo "Debugging: $1 is now ${!1}"
    else
      echo "Debugging: $2 already exists in $1"
    fi
  else
    echo "Debugging: Directory $2 does not exist"
  fi
}

echo "Debugging: Starting to process $tcsh_script_file"

while IFS= read -r line; do
  echo "Debugging: Processing line: $line"
  line=$(echo "$line" | sed 's/^\s*//')  # Remove leading whitespace
  echo "Debugging: Trimmed line: $line"

  if [[ $line =~ ^# ]]; then
    echo "Debugging: Skipping comment: $line"
    continue  # Skip comments
  elif [[ $line =~ ^alias[[:space:]]+([^[:space:]]+)[[:space:]]+(.*) ]]; then
    alias_name=${BASH_REMATCH[1]}
    alias_definition=${BASH_REMATCH[2]}
    echo "Debugging: Setting alias: $alias_name='$alias_definition'"
    alias "$alias_name"="$alias_definition"
  elif [[ $line =~ ^set[[:space:]]+([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*) ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    value=$(echo "$value" | sed 's/^"//; s/"$//')  # Remove surrounding quotes
    value=$(echo "$value" | sed 's/\\!/!/g')  # Remove escaping of '!' character
    echo "Debugging: Setting variable: $variable='$value'"
    eval "$variable=$value"
    export "$variable"
  elif [[ $line =~ ^setenv[[:space:]]+([^[:space:]]+)[[:space:]]+(.*) ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    value=$(echo "$value" | sed 's/\\!/!/g')  # Remove escaping of '!' character
    echo "Debugging: Setting environment variable: $variable='$value'"
    eval "$variable=$value"
    export "$variable"
  elif [[ $line =~ ^prepend[[:space:]]+([^[:space:]]+)[[:space:]]+(.*) ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    echo "Debugging: Prepending to variable: $variable, value: $value"
    prepend "$variable" "$value"
  elif [[ $line =~ ^extend[[:space:]]+([^[:space:]]+)[[:space:]]+(.*) ]]; then
    variable=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    echo "Debugging: Extending variable: $variable, value: $value"
    extend "$variable" "$value"
  else
    echo "Debugging: Evaluating unmatched line: $line"
    line=$(echo "$line" | sed 's/setenv/export/')  # Replace 'setenv' with 'export'
    eval "$line"
  fi
done < "$tcsh_script_file"

echo "Debugging: Finished processing $tcsh_script_file"
