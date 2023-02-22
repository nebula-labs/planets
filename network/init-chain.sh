#!/bin/bash

source vars.sh

BINARY=$1
DENOM=$2
DIR=$3
CHAIN_ID="test-${DENOM:1}"
KEYRING="test"
KEY="test"
KEY1="test1"
RELAYER_KEY="rly"

rm -rf $DIR
mkdir -p $DIR

# check if toml-cli is installed
if ! [ -x "$(command -v toml)" ]; then
  echo 'Error: toml-cli is not installed.' >&2
  echo 'Please install it by running: pip install toml-cli' >&2
  exit 1
fi

# Function updates the config based on a jq argument as a string
update_test_genesis () {
    # EX: update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
    cat $DIR/config/genesis.json | jq --arg DENOM "$2" "$1" > $DIR/config/tmp_genesis.json && mv $DIR/config/tmp_genesis.json $DIR/config/genesis.json
}

$BINARY init --chain-id $CHAIN_ID moniker --home $DIR

echo $MNEMONIC_1 | $BINARY keys add $KEY --keyring-backend $KEYRING --home $DIR --recover

echo $MNEMONIC_2 | $BINARY keys add $KEY1 --keyring-backend $KEYRING --home $DIR --recover

echo $MNEMONIC_3 | $BINARY keys add $RELAYER_KEY --keyring-backend $KEYRING --home $DIR --recover

# Allocate genesis accounts (cosmos formatted addresses)
$BINARY add-genesis-account $KEY "1000000000000${DENOM}" --keyring-backend $KEYRING --home $DIR

$BINARY add-genesis-account $KEY1 "1000000000000${DENOM}" --keyring-backend $KEYRING --home $DIR

$BINARY add-genesis-account $RELAYER_KEY "1000000000000${DENOM}" --keyring-backend $KEYRING --home $DIR

update_test_genesis '.app_state["gov"]["voting_params"]["voting_period"] = "50s"'
update_test_genesis '.app_state["mint"]["params"]["mint_denom"]=$DENOM' $DENOM
update_test_genesis '.app_state["gov"]["deposit_params"]["min_deposit"]=[{"denom": $DENOM,"amount": "1000000"}]' $DENOM
update_test_genesis '.app_state["crisis"]["constant_fee"]={"denom": $DENOM,"amount": "1000"}' $DENOM
update_test_genesis '.app_state["staking"]["params"]["bond_denom"]=$DENOM' $DENOM

# check if denom is ${DENOMS[0]} or ${DENOMS[1]}
if [[ $DENOM == ${DENOMS[1]} ]]; then
  # orai
  update_test_genesis '.app_state["interchainaccounts"]["host_genesis_state"]["params"]["allow_messages"]=["/ibc.applications.transfer.v1.MsgTransfer"]'
fi

toml set --toml-path $DIR/config/config.toml p2p.seeds ""
toml set --toml-path $DIR/config/config.toml rpc.laddr "tcp://0.0.0.0:26657"
toml set --toml-path $DIR/config/client.toml node "tcp://0.0.0.0:26657"
toml set --toml-path $DIR/config/app.toml api.swagger true
toml set --toml-path $DIR/config/app.toml api.enable true

# Sign genesis transaction
$BINARY gentx $KEY "1000000${DENOM}" --keyring-backend $KEYRING --chain-id $CHAIN_ID --home $DIR

# Collect genesis tx
$BINARY collect-gentxs --home $DIR

# Run this to ensure everything worked and that the genesis file is setup correctly
$BINARY validate-genesis --home $DIR