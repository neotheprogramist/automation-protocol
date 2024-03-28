#!/usr/bin/env bash

set -euo pipefail

USDC_TRANSFER_AMOUNT=5000
CAST_SEND_OUTPUT_FILE=cast-send-output.txt
CAST_SEND_SUCCESS_RESPONSE_PARAM=blockHash
FORGE_CREATE_OUTPUT_FILE=forge-create-output.txt
FORGE_CREATE_SUCCESS_RESPONSE_PARAM="Deployed"
ANVIL_PORT=8545

# Get the directory of the current script.
SCRIPT_DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR_PATH="${SCRIPT_DIR_PATH}/.."
SCRIPTS_TMP_DIR_PATH="${ROOT_DIR_PATH}/scripts-tmp"
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

print "Starting impersonate rich account..."

# Impersonate rich account with high number of USDC
cast_output=$(cast rpc anvil_impersonateAccount $UNLUCKY_USER_USDC_WALLET_ADDRESS)

# Trim whitespace from the output for a more accurate comparison
trimmed_cast_output=$(echo "$cast_output" | xargs)

# Verify impersonate account commend result.
if [ "$trimmed_cast_output" = "null" ]; then
  print "Successfully impersonate rich account."
else
  print "Impersonate rich account failed, command output below:"
  print "$trimmed_cast_output"
fi

# Verify if `scripts-tmp` directory already exists,
# if not, create it.
if [ ! -d "$SCRIPTS_TMP_DIR_PATH" ]; then
  mkdir -p "$SCRIPTS_TMP_DIR_PATH"
fi

print "\nStarting transfer USDC from rich wallet to our wallet from anvil..."

# Transfer USDC_TRANSFER_AMOUNT USDC from account to our Avil wallet.
cast send $USDC_CONTRACT_ADDRESS --from $UNLUCKY_USER_USDC_WALLET_ADDRESS "transfer(address,uint256)(bool)" $FIRST_ANVIL_WALLET_ADDRESS_ALICE $USDC_TRANSFER_AMOUNT --unlocked > "$CAST_SEND_OUTPUT_FILE_PATH" 2>&1

# Check if cast send output has CAST_SEND_SUCCESS_RESPONSE_PARAM param.
if grep -q "$CAST_SEND_SUCCESS_RESPONSE_PARAM" "$CAST_SEND_OUTPUT_FILE_PATH"; then
    print "Successfully transfered ${USDC_TRANSFER_AMOUNT} USDC to anvil wallet."
else
    print "USDC transfer to anvil wallet failed, check log details in ${CAST_SEND_OUTPUT_FILE_PATH}."
fi

print "\nDeploying smart contract on fork network...\n"

# Deploy smart contract on fork network.
forge create --rpc-url "http://localhost:${ANVIL_PORT}" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d src/TokenDelgator.sol:TokenDelegator | tee "$FORGE_CREATE_OUTPUT_FIILE_PATH"

# Check if forge create output has FORGE_CREATE_SUCCESS_RESPONSE_PARAM param.
if grep -q "$FORGE_CREATE_SUCCESS_RESPONSE_PARAM" "$FORGE_CREATE_OUTPUT_FIILE_PATH"; then
    print "\nSuccessfully deployed smart contract on fork network."
else
    print "\nSmart contract deployment on fork network failed."
fi
