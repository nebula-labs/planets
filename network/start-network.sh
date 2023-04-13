#!/bin/bash

FIRST_NETWORK=$1
SECOND_NETWORK=$2

# check that FIRST_NETWORK and SECOND_NETWORK are set
if [ -z "$FIRST_NETWORK" ] || [ -z "$SECOND_NETWORK" ]; then
    echo "Please specify the first and second networks to run the test"
    exit 1
fi

source vars.sh $FIRST_NETWORK $SECOND_NETWORK
cd network

start_docker() {
    name=$1

    docker-compose up -d $name
    docker-compose logs -f $name | sed -r -u "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" > logs/$name.log 2>&1 &

    printf "Waiting for $name to start..."

    ( tail -f -n0 logs/$name.log & ) | grep -q "finalizing commit of block"
    echo "Done"
}

# cleanup any stale state
docker-compose down
rm -rf config logs
mkdir logs

# init chain
bash init-chain.sh ${BINARY[0]} ${DENOMS[0]} ${CONFIG_DIR[0]} ${CHAINID[0]}
bash init-chain.sh ${BINARY[1]} ${DENOMS[1]} ${CONFIG_DIR[1]} ${CHAINID[1]}

# start docker
start_docker $FIRST_NETWORK
start_docker $SECOND_NETWORK

# start relayer
bash setup-relayer.sh

# ibc-transfer token from network 1 to network 2
${BINARY[1]} tx ibc-transfer transfer transfer channel-0 ${NETWORK_1_ADDRESSES[1]} 1000000000${DENOMS[1]} --from test1 --keyring-backend test --home ${CONFIG_DIR[1]} --chain-id ${CHAINID[1]} --fees 100000${DENOMS[1]} --yes --node ${NODE[1]}

cd ..