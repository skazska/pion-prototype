#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
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

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setPeerGlobals 0 Executor

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer0.orderer.prototype.rks.plus:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer0.orderer.prototype.rks.plus:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in Executor Producer Distributor Service Consumer Supervisor; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

updateAnchorPeer () {
	for org in Executor Producer Distributor Service Consumer Supervisor; do
        echo "Updating anchor peers for ${org}..."
        updateAnchorPeers 0 ${org}
        echo
	done
}

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


## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
updateAnchorPeer

## Install chaincode on peer0.org1 and peer0.org2
installPeerChaincode 0

# Instantiate chaincode on peer0.producer
echo "Instatiating chaincode on peer0 for Producer..."
instantiateChaincode 0 Producer
echo

instantiatePeerChaincode 0

# Query chaincode on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery 0 Executor 100

# Invoke chaincode on peer0.org1
echo "Sending invoke transaction on peer0.org1..."
chaincodeInvoke 0 Executor

## Install chaincode on peer1.org2
echo "Installing chaincode on peer1..."
installChaincode 1 Producer

# Query on chaincode on peer1.org2, check if the result is 90
echo "Querying chaincode on peer1.org2..."
chaincodeQuery 1 Producer 90

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
