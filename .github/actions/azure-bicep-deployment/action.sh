#!/bin/bash
echo $@

PROJECTNAME=$1
LOCATION=$2
DEPLOYMENT_NAME=$3
RG_TEMPLATE_FILE=$4
WORKSPACE_TEMPLATE_FILE=$5
TEMPLATE_VERSION=$6
PARAMETERS=$7

echo $PARAMETERS

az deployment sub create \
    --location $LOCATION \
    --template-file $RG_TEMPLATE_FILE \
    --name $DEPLOYMENT_NAME \
    --parameters projectName=$PROJECTNAME \
    --parameters location=$LOCATION

RESOURCE_GROUP=$(az group list --query "[?location=='$LOCATION']" --tag project=$PROJECTNAME | jq -r '.[0].name')

az ts create --name $DEPLOYMENT_NAME \
                --version "$TEMPLATE_VERSION" \
                --resource-group $RESOURCE_GROUP \
                --location $LOCATION \
                --template-file $WORKSPACE_TEMPLATE_FILE \
                --yes

SPECIFICATION_ID=$(az ts list --resource-group $RESOURCE_GROUP | jq -r '.[0].id')

if [[ "$PARAMETERS" == "" ]]; then
    az deployment group create --resource-group  RESOURCE_GROUP \
                                --name deployment01 \
                                --template-spec $SPECIFICATION_ID/versions/$TEMPLATE_VERSION
else
    az deployment group create --resource-group $RESOURCE_GROUP \
                            --name deployment01 \
                            --template-spec $SPECIFICATION_ID/versions/$TEMPLATE_VERSION \
                            --parameters $PARAMETERS
fi
