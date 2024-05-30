# Introduction 
To configure GreengrassCore V2 device in my ARM 18.04 ubuntu Linux ( currently I am using Guest VM, however these instruction will be useful for core-hardware devices if you have followed following steps from [README](README.md) 
- [Kernel tuning for Greengrass Core V2](README.md#kernel-tuning-for-greengrass-core-v2)
- [Step 7: Verify following commands else install them](README.md#step-7-configure-grub-for-cgroup-settings)

## My Approach for  GreengrassCore V2 in Ubuntu ARM 18.04 Installation and Configuration
Before proceeding I just want to let you know that I am little bit diverging from [AWS Greengrass Core V2 Manual installation guide](https://docs.aws.amazon.com/greengrass/v2/developerguide/manual-installation.html)

The simple reason is that I have to configure Greengrass Core V2 with multiple clients and for each client I am creating 

- Create an AWS IoT thing
  </br>I have specific naming convention for creating IoT Thing and Thing Type and Thing group based on my client project name. So this step I am using on my Lambda function [TODO](attach)
- Create the thing certificate
  </br>This also I am handling in my lambda function
- Configure the thing certificate
  </br>This also I am handling in my lambda function
- Configuring or Creating following : This I am doing as part of my Infrastructure as Code (IaC) script pipeline 
  - _GreengrassV2IoTThingPolicy_ 
  - Attach the AWS IoT policy to the AWS IoT thing's certificate
   </br> **NOTE**: This also I am handling in my lambda function
  - Create a token exchange role _GreengrassV2TokenExchangeRole_ :  : 
  - Create the IAM policy _GreengrassV2TokenExchangeRoleAccess_
  - Attach the IAM policy to the token exchange role _GreengrassV2TokenExchangeRole_
  - Create an AWS IoT role alias that points to the token exchange role. _GreengrassCoreTokenExchangeRoleAlias_
  - Create an AWS IoT policy _GreengrassCoreTokenExchangeRoleAliasPolicy_

## Installation GreengrassCoreV2 with Bash script
If you are also doing the same then here is the simple script to install and configure Green

**NOTE** Before running this make sure you have sudo access and you configure appropriate access key and security key in **aws cli** for you region 


save this file as `greengrasscore-installation.sh`  and run with `sudo ./greengrasscore-installation.sh`

[greengrasscore-installation.sh](greengrasscore-installation.sh) 



After installing AWS IoT Greengrass Core, you can verify that the Greengrass Core is running and properly configured by checking its status and ensuring that the required components and services are functioning correctly. Here's a step-by-step guide on how to do this:

### 1. Check Greengrass Core Status

#### Check Greengrass System Service

To verify that the Greengrass system service is running, use the `systemctl` command:

```bash
sudo systemctl status greengrass.service
```

This command should return the status of the Greengrass service. If the service is active and running, you should see output indicating that the service is running correctly. For example:

```
● greengrass.service - Greengrass
   Loaded: loaded (/etc/systemd/system/greengrass.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2024-05-28 16:34:23 UTC; 5min ago
```

### 2. Check Greengrass Logs

Greengrass logs provide detailed information about the Greengrass Core operations and any potential issues. The logs are typically located in the `/greengrass/v2/logs` directory.

You can view the logs using the `less` or `cat` command. For example:

```bash
sudo less /greengrass/v2/logs/greengrass.log
```

### 3. Validate Greengrass Components

To ensure that Greengrass components are functioning correctly, you can use the AWS IoT Greengrass CLI or check the AWS Management Console.

#### AWS IoT Greengrass CLI
Follow this [link](https://docs.aws.amazon.com/greengrass/v2/developerguide/install-gg-cli.html#gg-cli-deploy) to install greengrass-cli via AWS Console

```bash
sudo /greengrass/v2/bin/greengrass-cli list-components
```

This command should list all the components and their statuses, indicating whether they are running or not.

### 4. Next Steps

After verifying that Greengrass Core is running, you can proceed with the following steps:

#### Deploy a Greengrass Component

To deploy a component to the Greengrass Core device, you can use the AWS IoT Greengrass console or the AWS CLI. Here’s an example using the AWS CLI:

1. **Create a Component**: Define your component in a JSON or YAML file.
2. **Create a Deployment**: Deploy the component to your Greengrass Core device.

##### Example Component Definition

Create a `my-component.json` file:

```json
{
  "recipeFormatVersion": "2020-01-25",
  "componentName": "com.example.MyComponent",
  "componentVersion": "1.0.0",
  "componentDescription": "My custom component",
  "componentPublisher": "Me",
  "componentConfiguration": {
    "defaultConfiguration": {}
  },
  "manifests": [
    {
      "platforms": [
        {
          "os": "all"
        }
      ],
      "lifecycle": {
        "run": {
          "script": "echo Hello, World!"
        }
      }
    }
  ]
}
```

##### Create the Component

Use the AWS CLI to create the component:

```bash
aws greengrassv2 create-component-version --inline-recipe fileb://my-component.json
```

##### Create the Deployment

Create a `deployment.json` file:

```json
{
  "targetArn": "arn:aws:iot:<region>:<account-id>:thinggroup/MyGreengrassGroup",
  "components": {
    "com.example.MyComponent": {
      "componentVersion": "1.0.0"
    }
  }
}
```

Deploy the component:

```bash
aws greengrassv2 create-deployment --deployment-name MyDeployment --cli-input-json file://deployment.json
```

### Additional Resources

- **AWS IoT Greengrass Documentation**: [AWS IoT Greengrass V2](https://docs.aws.amazon.com/greengrass/v2/developerguide/what-is-gg.html)
- **AWS CLI Documentation**: [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/greengrassv2/index.html)
- **Greengrass CLI Commands**: [AWS IoT Greengrass V2 CLI](https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-cli.html)

By following these steps, you can verify that Greengrass Core is running correctly and proceed to deploy and manage components on your Greengrass Core device.

## Uninstall Greengrass core

Complete Uninstallation Script
```bash
#!/bin/bash

# Stop the Greengrass service
echo "Stopping Greengrass service..."
sudo systemctl stop greengrass.service

# Disable the Greengrass service
echo "Disabling Greengrass service..."
sudo systemctl disable greengrass.service

# Remove Greengrass directories
echo "Removing Greengrass directories..."
sudo rm -rf /greengrass
# Remove Greengrass users and groups
sudo userdel -r ggc_user
sudo groupdel ggc_group

# Remove Greengrass systemd service file
echo "Removing Greengrass systemd service file..."
sudo rm /etc/systemd/system/greengrass.service

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Verify removal
echo "Verifying Greengrass service removal..."
sudo systemctl list-units --type=service | grep greengrass

echo "Greengrass core uninstallation completed."
```
