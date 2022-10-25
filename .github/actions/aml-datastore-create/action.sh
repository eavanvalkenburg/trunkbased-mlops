#!/bin/bash
echo $@

DATASTORE_FILE_PATH=$1
WORKSPACE_NAME=$2
RESOURCE_GROUP=$3

az configure --defaults workspace=$WORKSPACE_NAME group=$RESOURCE_GROUP

echo "::debug::Looking for datastore definition at '$DATASTORE_FILE_PATH'"
DATASTORES_FILES=$(find $DATASTORE_FILE_PATH;)

for DATASTORE_FILE in $DATASTORES_FILES
do
    echo "::debug::Working with datastore '$DATASTORE_FILE'"
    DATASTORE_NAME=$(yq -r ".name" $DATASTORE_FILE)
    echo "::debug::DATASTORE_NAME=$DATASTORE_NAME"

    if [[ $(az ml datastore list --query "[?name == '$DATASTORE_NAME']" ) ]]; then
        echo "::debug::Datastore $DATASTORE_NAME already in target workspace."
    else
        echo "::debug::Datastore $DATASTORE_NAME is missing. Creating from file $DATASTORE_FILE."
        az ml datastore create --file $DATASTORE_FILE
    fi
done
