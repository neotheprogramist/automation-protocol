#!/usr/bin/env bash

set -euo pipefail

BLOCK_TIME=10
ANVIL_OUTPUT_FILE=anvil-fork-output.txt
# Condition after which we're stopping recording lines to file.
ANVIL_FORK_FILE_LINE_CONDITION="Listening on 127.0.0.1:"

# Get the directory of the current script.
SCRIPT_DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR_PATH="${SCRIPT_DIR_PATH}/.."
SCRIPTS_TMP_DIR_PATH="${ROOT_DIR_PATH}/scripts-tmp"

# Check if the CI environment variable exists - if not, set default value to `false`,
# if yes, check if it is set to `false`, which determines that we run script locally
# and we need to source environment variables.
if [ "${CI:-false}" = "false" ]; then
  # Construct the path to the `.env.local` file by navigating up one directory.
  ENV_LOCAL_FILE_PATH="${ROOT_DIR_PATH}/.env.local"

  # Check if the `.env.local` file exists.
  if [ ! -f "${ENV_LOCAL_FILE_PATH}" ]; then
      echo "Error: .env.local file does not exist at ${ENV_LOCAL_FILE_PATH} path."
      exit 1
  fi

  # Source the `.env.local` file in a way that supports non-exported variables.
  while IFS='=' read -r key value; do
    # Skip lines that are empty or start with a hash (comments).
    [[ -z $key || $key =~ ^# ]] && continue

    # Remove potential leading "export " in each line for file consistency.
    key=${key#export }

    # Use eval to correctly handle values with spaces.
    eval export "$key='$value'"

  # Do it through all lines in `.env.local` file.
  done < "${ENV_LOCAL_FILE_PATH}"
fi

# Verify if `scripts-tmp` directory already exists, if not, create it.
if [ ! -d "$SCRIPTS_TMP_DIR_PATH" ]; then
  mkdir -p "$SCRIPTS_TMP_DIR_PATH"
fi

# Start the process in the background and redirect output to a file descriptor.
exec {FD}>"${SCRIPTS_TMP_DIR_PATH}/${ANVIL_OUTPUT_FILE}"

ANVIL_CONTINUE_SAVE_TO_FILE=true

anvil --fork-url "https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_PRIVATE_API_KEY}" --block-time "$BLOCK_TIME" | while IFS= read -r line; do
  # Always output to console.
  echo "$line"
  
  # Conditional logging to file based on flag.
  if [[ "$ANVIL_CONTINUE_SAVE_TO_FILE" == true ]]; then
    echo "$line" > /dev/fd/$FD
  fi
  
  # Check condition to stop logging to file.
  if [[ $line == *"$ANVIL_FORK_FILE_LINE_CONDITION"* ]]; then
    ANVIL_CONTINUE_SAVE_TO_FILE=false
  fi
done
