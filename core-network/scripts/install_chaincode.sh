#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Install chaincode"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="basis"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/orderer.prototype.rks.plus/orderers/orderer0.orderer.prototype.rks.plus/msp/tlscacerts/tlsca.orderer.prototype.rks.plus-cert.pem

CC_SRC_PATH="github.com/skazska/pion-prototype-chaincode"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

installPeerChaincode () {
    local PEER=$1
	for org in Executor Producer Distributor Service Consumer Supervisor; do
        echo "Installing chaincode on peer0 for ${org}..."
        installChaincode ${PEER} ${org}
        echo
	done
}

#instantiatePeerChaincode () {
#    local PEER=$1
#	for org in Producer; do
#        echo "Instatiating chaincode on peer0 for ${org}..."
#        instantiateChaincode ${PEER} ${org}
#        echo
#	done
#}

## Install chaincode on peer0.org1 and peer0.org2
installPeerChaincode 0

# Instantiate chaincode on peer0.producer
echo "Instatiating chaincode on peer0 for Producer..."
instantiateChaincode 0 Producer
echo

#instantiatePeerChaincode 0

## Install chaincode on peer1.org2
echo "Installing chaincode on peer1..."
installChaincode 1 Producer

echo
echo "========= All GOOD, Install chaincode execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
