#!/bin/bash
# currently support only deploying on Aura

ACCOUNT="test"
SLEEP_TIME="15"
KEYRING="test"

FIRST_NETWORK=$1
SECOND_NETWORK=$2

# check that FIRST_NETWORK and SECOND_NETWORK are set
if [ -z "$FIRST_NETWORK" ] || [ -z "$SECOND_NETWORK" ]; then
    echo "Please specify the first and second networks to run the test"
    exit 1
fi

source vars.sh $FIRST_NETWORK $SECOND_NETWORK

CONTRACT_DIR=()
CONTRACT_NAME=()
CONTRACT_CHAIN=()
CONTRACT_ADDRESS=()

# loop through each network
for i in {1..2}; do
    wasm_list=($(find $ROOT/contract/wasm/network_$i -name "*.wasm"))
    CONTRACT_DIR+=($wasm_list)
    for wasm_dir in ${wasm_list[@]}; do
        CONTRACT_NAME+=($(basename $wasm_dir .wasm))
        CONTRACT_CHAIN+=($(($i - 1)))
        CONTRACT_ADDRESS+=('')
    done
done

echo ${CONTRACT_DIR[@]}
echo ${CONTRACT_NAME[@]}
echo ${CONTRACT_CHAIN[@]}
echo ${CONTRACT_ADDRESS[@]}

# check if a folder exists
if [ ! -d $ROOT/contract/logs ]; then
    mkdir $ROOT/contract/logs
fi

# construct init msg

# loop contracts
for j in $(seq 0 $((${#CONTRACT_DIR[@]} - 1))); do
    i=${CONTRACT_CHAIN[$j]}
    echo "DEPLOYING ${CONTRACT_DIR[$j]}"

    if [ "${INIT_MSG[$j]}" = "" ]; then
        continue
    fi

    # store contract
    RES=$(${BINARY[$i]} tx wasm store "${CONTRACT_DIR[$j]}" --from "$ACCOUNT" -y --output json --chain-id "${CHAINID[$i]}" --node "${NODE[$i]}" --gas 20000000 --fees 875000${DENOM[$i]} -y --output json --keyring-backend $KEYRING --home ${DIR[$i]})
    echo $RES

    if [ "$(echo $RES | jq -r .raw_log)" != "[]" ]; then
        # exit
        echo "ERROR = $(echo $RES | jq .raw_log)"
        exit 1
    else
        echo "STORE SUCCESS"
    fi

    TXHASH=$(echo $RES | jq -r .txhash)

    echo $TXHASH

    # sleep for chain to update
    sleep "$SLEEP_TIME"

    # query code id
    RAW_LOG=$(${BINARY[$i]} query tx "$TXHASH" --chain-id "${CHAINID[$i]}" --node "${NODE[$i]}" -o json | jq -r .raw_log)

    echo $RAW_LOG

    CODE_ID=$(echo $RAW_LOG | jq -r .[0].events[1].attributes[1].value)

    echo "CODE_ID on ${CHAINID[$i]} = $CODE_ID"

    # instantiate contract
    RES=$(${BINARY[$i]} tx wasm instantiate "$CODE_ID" "${INIT_MSG[$j]}" --from "$ACCOUNT" --no-admin --label "contract" -y --chain-id "${CHAINID[$i]}" --node "${NODE[$i]}" --gas 20000000 --fees 100000${DENOM[$i]} -o json --keyring-backend $KEYRING --home ${DIR[$i]})

    if [ "$(echo $RES | jq -r .raw_log)" != "[]" ]; then
        # exit
        echo "ERROR = $(echo $RES | jq .raw_log)"
        exit 1
    else
        echo "INSTANTIATE SUCCESS"
    fi

    # sleep for chain to update
    sleep "$SLEEP_TIME"

    # query contract address
    RAW_LOG=$(${BINARY[$i]} query tx "$(echo $RES | jq -r .txhash)" --chain-id "${CHAINID[$i]}" --node "${NODE[$i]}" -o json | jq -r .raw_log)
    echo $RAW_LOG
    ADDRESS=$(echo $RAW_LOG | jq -r .[0].events[0].attributes[0].value)
    CONTRACT_ADDRESS[$j]=$ADDRESS
    echo "CONTRACT ADDRESS of ${CONTRACT_NAME[$j]} on ${CHAINID[$i]} with address = $ADDRESS" >> scripts/contract-interaction/logs/contract-addresses.txt

    echo "DONE DEPLOYING ${CONTRACT_DIR[$j]}"
    echo
    echo
    echo
done

# write contract addresses to logs
sed -i "" "s|export SWAPROUTER_CONTRACT=.*|export SWAPROUTER_CONTRACT=${CONTRACT_ADDRESS[1]}|g" scripts/vars.sh
sed -i "" "s|export CROSSCHAIN_CONTRACT=.*|export CROSSCHAIN_CONTRACT=${CONTRACT_ADDRESS[2]}|g" scripts/vars.sh