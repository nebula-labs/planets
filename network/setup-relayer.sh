#!/bin/bash

# check if ROOT empty
if [ -z "$ROOT" ]; then
    source vars.sh $1 $2
fi

# get src-port, dst-port and version
SRC_PORT=$3
DST_PORT=$4
VERSION=$5

# check if SRC_PORT is empty
if [ -z "$SRC_PORT" ]; then
    SRC_PORT="transfer"
fi

# check if DST_PORT is empty
if [ -z "$DST_PORT" ]; then
    DST_PORT="transfer"
fi

# check if VERSION is empty
if [ -z "$VERSION" ]; then
    VERSION="ics20-1"
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

# default is transfer
printf "Waiting for relayer to start..."
$relayer_exec rly transact link "$FIRST_NETWORK-$SECOND_NETWORK" --src-port $SRC_PORT --dst-port $DST_PORT --version $VERSION >> $relayer_logs 2>&1

if [[ "${PIPESTATUS[0]}" = "1" ]]; then
    echo "Failed to link chains"
    exit 1
fi

docker-compose -f $ROOT/network/docker-compose.yml up -d "relayer-$FIRST_NETWORK-$SECOND_NETWORK"
docker-compose -f $ROOT/network/docker-compose.yml logs -f "relayer-$FIRST_NETWORK-$SECOND_NETWORK" | sed -r -u "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> $relayer_logs 2>&1 &

echo "Done"