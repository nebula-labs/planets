#!/bin/bash

FIRST_NETWORK=$1
SECOND_NETWORK=$2

# check that FIRST_NETWORK and SECOND_NETWORK are set
if [ -z "$FIRST_NETWORK" ] || [ -z "$SECOND_NETWORK" ]; then
    echo "Please specify the first and second networks to run the test"
    exit 1
fi

export ROOT=$(pwd)

export FIRST_NETWORK
export SECOND_NETWORK

export MNEMONIC_1="dry repeat crush category laugh proud pretty crew record crash neglect road valley soon solution flat poet fantasy space resist april owner ship business"
export MNEMONIC_2="supreme era pool truth shop essay source wall steel rely local wing convince enact champion warm food grunt siege obey kiss crane squeeze original"
export MNEMONIC_3="confirm select whale obtain toe fortune wisdom truck hospital cement spring when idea cupboard machine glory mouse kitchen moral fiber bomb rabbit fog raven"

export NETWORK_1_ADDRESSES=($(jq -r '.addresses | @sh' "$ROOT/template/$FIRST_NETWORK/config.json" | tr -d \'))
export NETWORK_2_ADDRESSES=($(jq -r '.addresses | @sh' "$ROOT/template/$SECOND_NETWORK/config.json" | tr -d \'))

NETWORK_1_BINARY=$(jq -r '."chain-binary"' "$ROOT/template/$FIRST_NETWORK/config.json")
NETWORK_1_DENOM=$(jq -r '.denom' "$ROOT/template/$FIRST_NETWORK/config.json")
NETWORK_1_ID=$(jq -r '."chain-id"' "$ROOT/template/$FIRST_NETWORK/config.json")
NETWORK_1_NODE=$(jq -r '.node' "$ROOT/template/$FIRST_NETWORK/config.json")

NETWORK_2_BINARY=$(jq -r '."chain-binary"' "$ROOT/template/$SECOND_NETWORK/config.json")
NETWORK_2_DENOM=$(jq -r '.denom' "$ROOT/template/$SECOND_NETWORK/config.json")
NETWORK_2_ID=$(jq -r '."chain-id"' "$ROOT/template/$SECOND_NETWORK/config.json")
NETWORK_2_NODE=$(jq -r '.node' "$ROOT/template/$SECOND_NETWORK/config.json")

export BINARY=( "$ROOT/build/binary/$NETWORK_1_BINARY" "$ROOT/build/binary/$NETWORK_2_BINARY" )
export CONFIG_DIR=( "$ROOT/network/config/$FIRST_NETWORK" "$ROOT/network/config/$SECOND_NETWORK" )
export DENOMS=( "$NETWORK_1_DENOM" "$NETWORK_2_DENOM" )
export NODE=( "$NETWORK_1_NODE" "$NETWORK_2_NODE" )
export CHAINID=( "$NETWORK_1_ID" "$NETWORK_2_ID" )