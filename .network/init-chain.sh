#!/bin/bash

BINARY=$1
DENOM=$2
DIR=$3
CHAIN_ID=$4
KEYRING="test"
KEY="test"
KEY1="test1"
RELAYER_KEY="rly"

rm -rf $DIR
mkdir -p $DIR

SED_BINARY=sed
# check if this is OS X
if [[ "$OSTYPE" == "darwin"* ]]; then
    # check if gsed is installed
    if ! command -v gsed &> /dev/null
    then
        echo "gsed could not be found. Please install it with 'brew install gnu-sed'"
        exit
    else
        SED_BINARY=gsed
    fi
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

$SED_BINARY -i '0,/enable = false/s//enable = true/' $HOME/config/app.toml
$SED_BINARY -i 's/swagger = false/swagger = true/' $HOME/config/app.toml
$SED_BINARY -i 's/laddr = "tcp:\/\/127\.0\.0\.1:26657"/laddr = "tcp:\/\/0\.0\.0\.0:26657"/' $DIR/config/config.toml
$SED_BINARY -i 's/node = "tcp:\/\/localhost:26657"/node = "tcp:\/\/0.0.0.0:26657"/' $DIR/config/client.toml

# Sign genesis transaction
$BINARY gentx $KEY "1000000${DENOM}" --keyring-backend $KEYRING --chain-id $CHAIN_ID --home $DIR

# Collect genesis tx
$BINARY collect-gentxs --home $DIR

# Run this to ensure everything worked and that the genesis file is setup correctly
$BINARY validate-genesis --home $DIR