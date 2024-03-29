#!/usr/bin/env bash

set -euo pipefail

FIRST_ANVIL_WALLET_ADDRESS=
FIRST_ANVIL_WALLET_PRIVATE_KEY=

USDC_TRANSFER_AMOUNT=570639343061169
ANVIL_OUTPUT_FILE=anvil-fork-output.txt
CAST_SEND_OUTPUT_FILE=cast-send-output.txt
CAST_SEND_SUCCESS_RESPONSE_PARAM=blockHash
FORGE_CREATE_OUTPUT_FILE=forge-create-output.txt
FORGE_CREATE_SUCCESS_RESPONSE_PARAM="Deployed"
ANVIL_PORT=8545

# Get the directory of the current script.
SCRIPT_DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR_PATH="${SCRIPT_DIR_PATH}/.."
SCRIPTS_TMP_DIR_PATH="${ROOT_DIR_PATH}/scripts-tmp"
FORK_OUTPUT_FILE_PATH="${SCRIPTS_TMP_DIR_PATH}/${ANVIL_OUTPUT_FILE}"
CAST_SEND_OUTPUT_FILE_PATH="${SCRIPTS_TMP_DIR_PATH}/${CAST_SEND_OUTPUT_FILE}"
FORGE_CREATE_OUTPUT_FIILE_PATH="${SCRIPTS_TMP_DIR_PATH}/${FORGE_CREATE_OUTPUT_FILE}"

# Print function that allows new lines character.
print() {
    echo -e "$1"
}

# Check if the CI environment variable exists - if not, set default value to `false`,
# if yes, check if it is set to `false`, which determines that we run script locally
# and we need to source environment variables.
if [ "${CI:-false}" = "false" ]; then
  # Construct the path to the `.env` file by navigating up one directory.
  ENV_FILE_PATH="${ROOT_DIR_PATH}/.env"

  # Check if the `.env` file exists.
  if [ ! -f "${ENV_FILE_PATH}" ]; then
      print "Error: .env file does not exist at ${ENV_FILE_PATH} path."
      exit 1
  fi

  # Source the `.env` file in a way that supports non-exported variables.
  while IFS='=' read -r key value; do
    # Skip lines that are empty or start with a hash (comments).
    [[ -z $key || $key =~ ^# ]] && continue

    # Remove potential leading "export " in each line for file consistency.
    key=${key#export }

    # Use eval to correctly handle values with spaces.
    eval export "$key='$value'"

  # Do it through all lines in `.env` file.
  done < "${ENV_FILE_PATH}"
fi

# Check if `fork-mainnet.sh` was run before (by validating anvil-fork-output.txt file).
if [ ! -f "$FORK_OUTPUT_FILE_PATH" ]; then
    print "Please run fork-mainnet.sh script before running this one. Exiting."
    exit 1
fi

# Parse file line by line and set flag to 1 when "Available Accounts" are encountered
# and set flag to 0 when "Private Keys" are encountered and stop processing.
# If flag is set and line starts with a number in parentheses - print the second field (the account address).
FIRST_ANVIL_WALLET_ADDRESS=$(awk '/Available Accounts/{flag=1; next} /Private Keys/{flag=0} flag && /^\([0-9]+\)/{print $2; exit}' "$FORK_OUTPUT_FILE_PATH")

# Check if we successfully extracted an address.
if [ ! -n "${FIRST_ANVIL_WALLET_ADDRESS}" ]; then
    print "Unable to find a wallet address in the ${FORK_OUTPUT_FILE_PATH} file."
    exit 1
fi

# Searches for all occurrences of patterns that match a private key (starting with 0x followed by 64 hexadecimal characters).
# Stop after the first match.
FIRST_ANVIL_WALLET_PRIVATE_KEY=$(awk '/Private Keys/{flag=1; next} /Wallet/{flag=0} flag && /^\([0-9]+\)/{print $2; exit}' "$FORK_OUTPUT_FILE_PATH")

# Check if we successfully extracted a private key.
if [ ! -n "${FIRST_ANVIL_WALLET_PRIVATE_KEY}" ]; then
    print "Unable to find a wallet private key in the ${FORK_OUTPUT_FILE_PATH} file."
    exit 1
fi

print "Starting impersonate rich account..."

# Impersonate rich account with high number of USDC.
cast_output=$(cast rpc anvil_impersonateAccount $UNLUCKY_USER_USDC_WALLET_ADDRESS)

# Trim whitespace from the output for a more accurate comparison.
trimmed_cast_output=$(echo "$cast_output" | xargs)

# Verify impersonate account commend result.
if [ "$trimmed_cast_output" = "null" ]; then
  print "Successfully impersonate rich account."
else
  print "Impersonate rich account failed, command output below:"
  print "$trimmed_cast_output"
fi

# Verify if `scripts-tmp` directory already exists, if not, create it.
if [ ! -d "$SCRIPTS_TMP_DIR_PATH" ]; then
  mkdir -p "$SCRIPTS_TMP_DIR_PATH"
fi

print "\nStarting transfer USDC from rich wallet to our wallet from anvil..."

# Transfer USDC_TRANSFER_AMOUNT USDC from account to our Avil wallet.
cast send $USDC_CONTRACT_ADDRESS --from $UNLUCKY_USER_USDC_WALLET_ADDRESS "transfer(address,uint256)(bool)" "$FIRST_ANVIL_WALLET_ADDRESS" $USDC_TRANSFER_AMOUNT --unlocked > "$CAST_SEND_OUTPUT_FILE_PATH" 2>&1

# Check if cast send output has CAST_SEND_SUCCESS_RESPONSE_PARAM param.
if grep -q "$CAST_SEND_SUCCESS_RESPONSE_PARAM" "$CAST_SEND_OUTPUT_FILE_PATH"; then
    print "Successfully transfered ${USDC_TRANSFER_AMOUNT} USDC to anvil wallet."
else
    print "USDC transfer to anvil wallet failed, check log details in ${CAST_SEND_OUTPUT_FILE_PATH}."
fi

print "\nDeploying smart contract on fork network...\n"

# Deploy smart contract on fork network.
forge create --rpc-url "http://localhost:${ANVIL_PORT}" --private-key "$FIRST_ANVIL_WALLET_PRIVATE_KEY" src/TokenDelgator.sol:TokenDelegator | tee "$FORGE_CREATE_OUTPUT_FIILE_PATH"

# Check if forge create output has FORGE_CREATE_SUCCESS_RESPONSE_PARAM param.
if grep -q "$FORGE_CREATE_SUCCESS_RESPONSE_PARAM" "$FORGE_CREATE_OUTPUT_FIILE_PATH"; then
    print "\nSuccessfully deployed smart contract on fork network."
else
    print "\nSmart contract deployment on fork network failed."
fi
