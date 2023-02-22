#!/bin/bash

FIRST_NETWORK=$1
SECOND_NETWORK=$2

# check that FIRST_NETWORK and SECOND_NETWORK are set
if [ -z "$FIRST_NETWORK" ] || [ -z "$SECOND_NETWORK" ]; then
    echo "Please specify the first and second networks to run the test"
    exit 1
fi

export ROOT=$(pwd)

export MNEMONIC_1="dry repeat crush category laugh proud pretty crew record crash neglect road valley soon solution flat poet fantasy space resist april owner ship business"
export MNEMONIC_2="supreme era pool truth shop essay source wall steel rely local wing convince enact champion warm food grunt siege obey kiss crane squeeze original"
export MNEMONIC_3="confirm select whale obtain toe fortune wisdom truck hospital cement spring when idea cupboard machine glory mouse kitchen moral fiber bomb rabbit fog raven"

export NETWORK_1_ADDRESSES=$(jq '.addresses' "$ROOT/template/$FIRST_NETWORK/config.json")
export NETWORK_2_ADDRESSES=$(jq '.addresses' "$ROOT/template/$SECOND_NETWORK/config.json")

NETWORK_1_BINARY=$(jq -r '."chain-binary"' "$ROOT/template/$FIRST_NETWORK/config.json")
NETWORK_1_DENOM=$(jq -r '.denom' "$ROOT/template/$FIRST_NETWORK/config.json")
NETWORK_1_ID=$(jq -r '."chain-id"' "$ROOT/template/$FIRST_NETWORK/config.json")

NETWORK_2_BINARY=$(jq -r '."chain-binary"' "$ROOT/template/$SECOND_NETWORK/config.json")
NETWORK_2_DENOM=$(jq -r '.denom' "$ROOT/template/$SECOND_NETWORK/config.json")
NETWORK_2_ID=$(jq -r '."chain-id"' "$ROOT/template/$SECOND_NETWORK/config.json")

export BINARY=( "$ROOT/build/binary/$NETWORK_1_BINARY" "$ROOT/build/binary/$NETWORK_2_BINARY" )
export DIR=( "$ROOT/network/config/$FIRST_NETWORK" "$ROOT/network/config/$SECOND_NETWORK" )
export DENOMS=( "$NETWORK_1_DENOM" "$NETWORK_2_DENOM" )
export NODE=( "http://localhost:26657" "http://localhost:26357" )
export CHAINID=( "$NETWORK_1_ID" "$NETWORK_2_ID" )