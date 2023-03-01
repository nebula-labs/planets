#!/bin/bash
# contract download script. This script can help downloading a variety of contracts from CosmWasm

contract=$1
tag=$2
network_num=$3

# check if tag is not set
if [ -z "$tag" ]; then
  tag="v1.0.1"
fi

# check if contract is not set
if [ -z "$contract" ]; then
  echo "YOU SHOULD SET WHICH CONTRACT YOU WANT TO DOWNLOAD"
  echo "DEFAULT ON CW20_IC20"
  contract="cw20_ics20"
fi

# check if network_num is not set
if [ -z "$network_num" ]; then
  echo "YOU SHOULD SET WHERE THIS WASM FILE WILL BELONG TO WHICH NETWORK"
  echo "DEFAULT ON FIRST NETWORK"
  network_num=1
fi

# TODO: there is a need for a CosmWasm registry to quickly fetch smart contract
# currently download cw20_ics20 from github release
url="https://github.com/CosmWasm/cw-plus/releases/download/$tag/${contract}.wasm"
json_url="https://github.com/CosmWasm/cw-plus/releases/download/$tag/${contract//_/-}.json"

echo "Downloading $url ..."
wget -O contract/wasm/"network_$network_num/${contract}.wasm" "$url"

echo "Downloading $json_url ..."
wget -O contract/schema/"network_$network_num/${contract}.json" "$json_url"
wget -qO- "$json_url" | jq -r '.instantiate' > contract/init_msg/"network_$network_num/${contract}_init.json"