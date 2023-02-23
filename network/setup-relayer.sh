#!/bin/bash

# check if ROOT empty
if [ -z "$ROOT" ]; then
    source vars.sh $1 $2
fi

docker container stop relayer &>/dev/null
docker container rm relayer &>/dev/null
rm -rf $ROOT/network/config/relayer-config $ROOT/network/logs/relayer.log

relayer_config=$ROOT/network/config/relayer-config/config
relayer_logs=$ROOT/network/logs/relayer.log
relayer_exec="docker-compose -f $ROOT/network/docker-compose.yml run --rm relayer-$FIRST_NETWORK-$SECOND_NETWORK"

mkdir -p $relayer_config
# modify relayer-config.yaml to reflect the correct contract address
cp $ROOT/network/relayer-config.yaml $relayer_config/config.yaml

$relayer_exec rly keys restore "$FIRST_NETWORK" "rly-$FIRST_NETWORK" "$MNEMONIC_3" >> $relayer_logs 2>&1
$relayer_exec rly keys restore "$SECOND_NETWORK" "rly-$SECOND_NETWORK" "$MNEMONIC_3" >> $relayer_logs 2>&1

printf "Waiting for relayer to start..."
$relayer_exec rly transact link "$FIRST_NETWORK-$SECOND_NETWORK" >> $relayer_logs 2>&1

if [[ "${PIPESTATUS[0]}" = "1" ]]; then
    echo "Failed to link chains"
    exit 1
fi

docker-compose -f $ROOT/network/docker-compose.yml up -d "relayer-$FIRST_NETWORK-$SECOND_NETWORK"
docker-compose -f $ROOT/network/docker-compose.yml logs -f "relayer-$FIRST_NETWORK-$SECOND_NETWORK" | sed -r -u "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> $relayer_logs 2>&1 &

echo "Done"

# quick commands
# ./build/binary/$FIRST_NETWORKd tx ibc-transfer transfer transfer channel-0 osmo15hh4c5dzwdy6alx6uzc5c2hzd3eu2dn2588m70 1000000000ujuno --from test1 --keyring-backend test --home scripts/network/config/juno --chain-id test-juno --fees 100000ujuno --yes --node tcp://localhost:26657
# ./build/binary/$SECOND_NETWORKd tx gamm create-pool --pool-file scripts/network/juno-osmosis-pool.json --from test1 --keyring-backend test --home scripts/network/config/osmosis --chain-id test-osmo --fees 100000uosmo --yes --node tcp://localhost:26357