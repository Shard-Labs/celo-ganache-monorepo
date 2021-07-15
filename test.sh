#!/bin/bash
set -e

URL=http://localhost:8545
ACC1=0xE36Ea790bc9d7AB70C55260C66D52b1eca985f84
ACC2=0xE834EC434DABA538cd1b9Fe1582052B880BD7e63
VAL=1e18

# set callGasLimit to 1e6
init() {
    packages/ganache-cli/cli.js --callGasLimit 0xF4240 -q ganache &
    SERVER_PID=$!
    sleep 10 # allow server to get up
}

end() {
    kill -SIGINT $SERVER_PID
}

trap "end" err exit

RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

# $1: acc, $2: currency, $3: amount
check() {
    TEST_OUT=test.out
    NO_SYNCCHECK=true celocli account:balance $1 --node $URL > $TEST_OUT

    ACTUAL=$(grep "^$2" $TEST_OUT)
    EXPECTED="$2: $3"
    if [ "$ACTUAL" = "$EXPECTED" ]; then
        printf " ${GREEN}OK${NO_COLOR}\n"
    else
        printf " ${RED}ERR\n"
        printf " Expected: \"$EXPECTED\"\n"
        printf " Actual: \"$ACTUAL\"${NO_COLOR}\n"
    fi

    rm $TEST_OUT
}

echo "1) Transfer: dollars; Gas fee: dollars" # 93769 gas, but gas data doesn't match this
init
NO_SYNCCHECK=true celocli transfer:dollars --from $ACC1 --to $ACC2 --value $VAL --node $URL --gasCurrency cUSD
echo "Checks:"
check $ACC1 CELO 2e+26
check $ACC1 cUSD 4.9998999962764e+22
check $ACC2 CELO 2e+26
check $ACC2 cUSD 5.0001e+22
echo
end

echo "2) Transfer: dollars; Gas fee: celo" # 50235 gas
init
NO_SYNCCHECK=true celocli transfer:dollars --from $ACC1 --to $ACC2 --value $VAL --node $URL --gasCurrency celo
echo "Checks:"
check $ACC1 CELO 1.999999999989953e+26
check $ACC1 cUSD 4.9999e+22
check $ACC2 CELO 2e+26
check $ACC2 cUSD 5.0001e+22
echo
end

echo "3) Transfer: celo; Gas fee: celo" # 38489 gas
init
NO_SYNCCHECK=true celocli transfer:celo --from $ACC1 --to $ACC2 --value $VAL --node $URL --gasCurrency celo
echo "Checks:"
check $ACC1 CELO 1.9999999899923022e+26
check $ACC1 cUSD 5e+22
check $ACC2 CELO 2.00000001e+26
check $ACC2 cUSD 5e+22
echo
end

echo "4) Transfer: celo; Gas fee: dollars"
init
NO_SYNCCHECK=true celocli transfer:celo --from $ACC1 --to $ACC2 --value $VAL --node $URL --gasCurrency cUSD
echo "Checks:"
check $ACC1 CELO 1.99999999e+26
check $ACC1 cUSD 4.9999999968637e+22
check $ACC2 CELO 2.00000001e+26
check $ACC2 cUSD 5e+22
echo
end
