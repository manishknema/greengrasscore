
#!/bin/bash
# Configuration variables
THING_NAME="<yourIoT Thing Name>"
THING_GROUP_NAME="<your Iot Thing Group>"
CERTIFICATE_NAME="${THING_NAME}_certificate.pem.crt"
PRIVATE_KEY_NAME="${THING_NAME}_private.pem.key"
CERTIFICATE_URL="https://<server_url>/${CERTIFICATE_NAME}"
PRIVATE_KEY_URL="https://<server_url>/${PRIVATE_KEY_NAME}"
ROOT_CA_URL="https://www.amazontrust.com/repository/AmazonRootCA1.pem"
GREENGRASS_INSTALL_DIR="/greengrass/v2"
GREENGRASS_CONFIG_FILE="$GREENGRASS_INSTALL_DIR/config.yaml"
AWS_REGION=$(aws configure get region)
THING_POLICY_NAME="GreengrassV2IoTThingPolicy"
ROLE_NAME="GreengrassV2TokenExchangeRole"
ROLE_ALIAS_NAME="GreengrassCoreTokenExchangeRoleAlias"

# Retrieve AWS Account ID and Region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# Verify the AccountID and Region retrieval
if [ -z "$ACCOUNT_ID" ]; then
    echo "Failed to retrieve AWS Account ID"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "Failed to retrieve AWS Region"
    exit 1
fi

echo "AWS Account ID: $ACCOUNT_ID"
echo "AWS Region: $REGION"

# Retrieve IoT Data Endpoint
IOT_DATA_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query endpointAddress --output text)
if [ -z "$IOT_DATA_ENDPOINT" ]; then
    echo "Failed to retrieve IoT Data Endpoint"
    exit 1
fi

# Retrieve IoT Credential Endpoint
IOT_CRED_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:CredentialProvider --query endpointAddress --output text)
if [ -z "$IOT_CRED_ENDPOINT" ]; then
    echo "Failed to retrieve IoT Credential Endpoint"
    exit 1
fi

echo "IoT Data Endpoint: $IOT_DATA_ENDPOINT"
echo "IoT Credential Endpoint: $IOT_CRED_ENDPOINT"

# Download the certificate, private key, and root CA
echo "Downloading the certificate..."
curl -o certificate.pem.crt $CERTIFICATE_URL

echo "Downloading the private key..."
curl -o private.pem.key $PRIVATE_KEY_URL

echo "Downloading the Amazon Root CA..."
curl -o AmazonRootCA1.pem $ROOT_CA_URL

# Ensure the Greengrass installation directory exists
mkdir -p $GREENGRASS_INSTALL_DIR

# Download and install the AWS IoT Greengrass V2 software
echo "Downloading the AWS IoT Greengrass V2 software..."
wget -O greengrass-v2-latest.zip https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-nucleus-latest.zip
unzip greengrass-v2-latest.zip -d $GREENGRASS_INSTALL_DIR
rm greengrass-v2-latest.zip

# Get the Greengrass version
GREENGRASS_VERSION=$(java -jar $GREENGRASS_INSTALL_DIR/lib/Greengrass.jar --version | awk '{print $3}')

if [ -z "$GREENGRASS_VERSION" ]; then
    echo "Failed to retrieve Greengrass version"
    exit 1
fi

echo "Greengrass Version: $GREENGRASS_VERSION"

# Move certificate, private key, and root CA to the Greengrass installation directory
mv certificate.pem.crt $GREENGRASS_INSTALL_DIR/device.pem.crt
mv private.pem.key $GREENGRASS_INSTALL_DIR/private.pem.key
mv AmazonRootCA1.pem $GREENGRASS_INSTALL_DIR/AmazonRootCA1.pem

# Create the Greengrass configuration file
cat <<EOF > $GREENGRASS_CONFIG_FILE
---
system:
  certificateFilePath: "/greengrass/v2/device.pem.crt"
  privateKeyPath: "/greengrass/v2/private.pem.key"
  rootCaPath: "/greengrass/v2/AmazonRootCA1.pem"
  rootpath: "/greengrass/v2"
  thingName: "$THING_NAME"
services:
  aws.greengrass.Nucleus:
    componentType: "NUCLEUS"
    version: "$GREENGRASS_VERSION"
    configuration:
      awsRegion: "$AWS_REGION"
      iotRoleAlias: "$ROLE_ALIAS_NAME"
      iotDataEndpoint: "$IOT_DATA_ENDPOINT"
      iotCredEndpoint: "$IOT_CRED_ENDPOINT"
EOF

# Ensure the Greengrass user and group exist
if ! id -u ggc_user > /dev/null 2>&1; then
    sudo useradd --system --create-home ggc_user
fi
if ! getent group ggc_group > /dev/null 2>&1; then
     sudo groupadd --system ggc_group
fi
# Install Greengrass core software
echo "Installing Greengrass core software..."
sudo -E java -Droot="$GREENGRASS_INSTALL_DIR" -Dlog.store=FILE -jar $GREENGRASS_INSTALL_DIR/lib/Greengrass.jar \
	  --aws-region $AWS_REGION \
	  --thing-name $THING_NAME \
	  --thing-group-name $THING_GROUP_NAME \
	  --thing-policy-name $THING_POLICY_NAME \
	  --tes-role-name $ROLE_NAME \
          --tes-role-alias-name $ROLE_ALIAS_NAME \
          --component-default-user ggc_user:ggc_group \
          --provision false \
	  --setup-system-service true \
          --deploy-dev-tools true\
	  --init-config  $GREENGRASS_CONFIG_FILE
echo "Greengrass core installation completed."
