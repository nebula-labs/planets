#!/bin/sh

# init chain
$binary init --chain-id $CHAIN_ID moniker

# add keys, add balances
for i in $(seq 0 3); do
    key=$(jq ".keys[$i] | tostring" entrypoint/keys.json )
    keyname=$(echo $key | jq -r 'fromjson | ."keyring-keyname"')
    mnemonic=$(echo $key | jq -r 'fromjson | .mnemonic')
    # Add new account
    echo $mnemonic | $binary keys add $keyname --keyring-backend $KEYRING --recover
    # Add initial balances
    $binary add-genesis-account $keyname "1000000000000uluna" --keyring-backend $KEYRING
done