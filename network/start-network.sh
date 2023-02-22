#!/bin/bash

source vars.sh
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
bash init-chain.sh $ROOT/build/binary/aurad uaura $ROOT/network/config/aura
bash init-chain.sh $ROOT/build/binary/oraid uorai $ROOT/network/config/orai

# start docker
start_docker aura
start_docker orai

# start relayer
bash setup-relayer.sh

# ibc-transfer orai to aura
${BINARY[1]} tx ibc-transfer transfer transfer channel-0 $AURA_2 1000000000uorai --from test1 --keyring-backend test --home ${DIR[1]} --chain-id test-orai --fees 100000uorai --yes --node ${NODE[1]}

cd ..