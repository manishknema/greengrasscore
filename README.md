- [Setting Up ARM-based Ubuntu 18.04 for AWS Greengrass Core](#setting-up-arm-based-ubuntu-1804-for-aws-greengrass-core)
  - [Using EC2](#using-ec2)
    - [Step 1: Create and Attach a New EBS Volume](#step-1-create-and-attach-a-new-ebs-volume)
    - [Step 2: Prepare and Mount the EBS Volume on the EC2 Instance](#step-2-prepare-and-mount-the-ebs-volume-on-the-ec2-instance)
    - [Step 4: Configure `/etc/fstab` for Automatic Mounting](#step-4-configure-etcfstab-for-automatic-mounting)
  - [AWS Greegrass Lambda function languages](#aws-greegrass-lambda-function-languages)
- [Greengrass V2 prerequisites](#greengrass-v2-prerequisites)
    - [Create an Administrator user in IAM in AWS Console](#create-an-administrator-user-in-iam-in-aws-console)
    - [Setup Python 3.10](#setup-python-310)
      - [Step-by-Step Instructions:](#step-by-step-instructions)
      - [Setting Python 3.10 as the Default Python Version (Optional)](#setting-python-310-as-the-default-python-version-optional)
      - [Installing Pip for Python 3.10](#installing-pip-for-python-310)
    - [Install AWS CLI](#install-aws-cli)
  - [Why QEMU](#why-qemu)
    - [Recommended Approach: QEMU](#recommended-approach-qemu)
- [Setting Up ARM-based Ubuntu 18.04 for AWS Greengrass Core on Windows 11](#setting-up-arm-based-ubuntu-1804-for-aws-greengrass-core-on-windows-11)
  - [Step 1: Install Chocolatey on Windows 11](#step-1-install-chocolatey-on-windows-11)
  - [Step 3: Download and Use `QEMU_EFI.fd`](#step-3-download-and-use-qemu_efifd)
  - [Step 4: Create the Ubuntu 18.04 ARM aarch64 Base Image](#step-4-create-the-ubuntu-1804-arm-aarch64-base-image)
  - [Step 5: Configure OpenSSH in the Guest VM](#step-5-configure-openssh-in-the-guest-vm)
  - [Step 6: Clone the Base VM for Multiple Instances](#step-6-clone-the-base-vm-for-multiple-instances)
    - [Kernel tuning for Greengrass Core V2](#kernel-tuning-for-greengrass-core-v2)
    - [Step-by-Step Guide to Enable Source Repositories and Download Kernel Source](#step-by-step-guide-to-enable-source-repositories-and-download-kernel-source)
    - [Step-by-Step Guide to Manually Edit the Kernel Configuration](#step-by-step-guide-to-manually-edit-the-kernel-configuration)
      - [Step 1: Download the Kernel Source Code](#step-1-download-the-kernel-source-code)
      - [Step 2: Copy Current Kernel Configuration](#step-2-copy-current-kernel-configuration)
      - [Step 3: Manually Edit the `.config` File](#step-3-manually-edit-the-config-file)
      - [Step 4: Compile and Install the Kernel](#step-4-compile-and-install-the-kernel)
      - [Step 5: Update Bootloader](#step-5-update-bootloader)
      - [Step 6: Verify the Configuration](#step-6-verify-the-configuration)
    - [Step 7: Configure GRUB for cgroup Settings](#step-7-configure-grub-for-cgroup-settings)
  - [Step 7: Verify following commands else install them](#step-7-verify-following-commands-else-install-them)
      - [Check glibc version](#check-glibc-version)
      - [The /tmp directory must be mounted with exec permissions.](#the-tmp-directory-must-be-mounted-with-exec-permissions)
      - [Install Java or openjdk](#install-java-or-openjdk)
      - [apt\_pkg not found issue](#apt_pkg-not-found-issue)
      - [Reasons to Use Supported Versions (Python 3.7 or 3.8)](#reasons-to-use-supported-versions-python-37-or-38)
      - [Installing Python 3.8 on Ubuntu 18.04](#installing-python-38-on-ubuntu-1804)
      - [Installing Python Packages](#installing-python-packages)
      - [Summary](#summary)
      - [Installing AWS CLI](#installing-aws-cli)
        - [Step 1: Update Your Package List](#step-1-update-your-package-list)
        - [Step 2: Install Required Packages](#step-2-install-required-packages)
        - [Step 3: Download the AWS CLI Installation Script](#step-3-download-the-aws-cli-installation-script)
        - [Step 4: Unzip the Installation Script](#step-4-unzip-the-installation-script)
        - [Step 5: Run the Installation Script](#step-5-run-the-installation-script)
        - [Step 6: Verify the Installation](#step-6-verify-the-installation)
        - [Step 7: Configure the AWS CLI](#step-7-configure-the-aws-cli)
  - [Running multiple instances of same qcow2 image in QEMU](#running-multiple-instances-of-same-qcow2-image-in-qemu)
  - [Step 8: Experiment with AWS Greengrass Core V2](#step-8-experiment-with-aws-greengrass-core-v2)
  - [Summary](#summary-1)

# Setting Up ARM-based Ubuntu 18.04 for AWS Greengrass Core
I wanted to see for one project how [AWS Greengrass Core V2](https://docs.aws.amazon.com/greengrass/v2/developerguide/what-is-iot-greengrass.html) is beneficial for local processing and Since most of the IoT Edge devices are based on the ARM architecture and very constraint typically 8-12 GB RAM and 10-100 GB Disk with/without GPU/NPU. I want to test out features of Greengrass before going full blown deployment in actual devices. 

## Using EC2 

You can alternatively try Ubuntu 22.04 based ARM (aarch64) machine I have used later after QEMU based installation and check the [Kernel tuning for Greengrass Core V2](#kernel-tuning-for-greengrass-core-v2) Here is what I have used
- output of `cat /etc/lsb-release`
```plaintext
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04 LTS" 
````
- The EC2 type 't4g.xlarge' vCPU=4 Memory=16GiB, I have also attached extra 100GB of volume

As per the [page](https://docs.aws.amazon.com/greengrass/v2/developerguide/setting-up.html) I didnt have enough space in root volume so I have attached separate disk for the EC2 instance with 100 GB of volume and here is how i setup space for */tmp* and */greengrass* on new disk

To set up a new 100GB disk on your EC2 instance and mount both `/tmp` and the Greengrass software directory to this new disk, follow these steps:

### Step 1: Create and Attach a New EBS Volume

1. **Create the EBS Volume**:
   - Go to the AWS Management Console.
   - Navigate to the EC2 Dashboard.
   - Click on "Volumes" under the "Elastic Block Store" section.
   - Click on "Create Volume."
   - Specify the size as 100GB and select the appropriate volume type.
   - Ensure the Availability Zone matches that of your EC2 instance.
   - Click "Create Volume."

2. **Attach the Volume to Your EC2 Instance**:
   - After creating the volume, select it from the "Volumes" list.
   - Click "Actions" and choose "Attach Volume."
   - Select your EC2 instance from the dropdown.
   - Specify a device name (e.g., `/dev/sdf`).
   - Click "Attach Volume."

### Step 2: Prepare and Mount the EBS Volume on the EC2 Instance

1. **SSH into Your EC2 Instance**:
   - Use SSH to connect to your instance:
     ```sh
     ssh -i /path/to/your-key.pem ec2-user@your-instance-public-dns
     ```

2. **List the Available Disks**:
   - Run the following command to list all attached disks:
     ```sh
     lsblk
     ```
     or 

     ```sh
     fdisk -l
     ```
   - Look for the newly attached disk (e.g., `/dev/nvme1n1`).
   - the output will be something like this for `fdisk -l` command
    ```sh
    Disk /dev/loop0: 21.84 MiB, 22904832 bytes, 44736 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/loop1: 49.12 MiB, 51503104 bytes, 100592 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/loop2: 33.65 MiB, 35287040 bytes, 68920 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/nvme1n1: 100 GiB, 107374182400 bytes, 209715200 sectors
    Disk model: Amazon Elastic Block Store
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
   ```
   Here I can see `/dev/nvme1n1: 100 GiB` is my newly added EBS volume

3. **Check if the Disk is Already Formatted**:
   - Use the `file` command to check if the disk has a filesystem:
     ```sh
     sudo file -s /dev/nvme1n1
     ```
    if the output doesnt show any filesystem like `ext4` or `ext3` then it will look like this
    ```sh
    /dev/nvme1n1: data
    ```
4. **Format the Disk (if necessary)**:
   - If the disk is not formatted, format it with the ext4 filesystem:
     ```sh
     sudo mkfs -t ext4 /dev/nvme1n1
     ```

5. **Create Mount Points**:
   - Create directories for mounting the new disk:
     ```sh
     sudo mkdir -p /mnt/newdisk
     
     ```

6. **Mount the Disk**:
   - Mount the disk to the new mount point:
     ```sh
     sudo mount /dev/nvme1n1 /mnt/newdisk
     ```
   - Create `/tmp` and `/greengrass` directories in `/mnt/newdisk`
    ```sh
    sudo mkdir -p /mnt/newdisk/tmp
    sudo mkdir -p /mnt/newdisk/greengrass
    ```
7. **Verify the Mount**:
   - Check that the disk is mounted correctly:
     ```sh
     df -h
     ```
    it should show the new disk `/dev/nvme1n1` mounted on `/mnt/newdisk`
    ```sh
    Filesystem       Size  Used Avail Use% Mounted on
    /dev/root        6.8G  1.6G  5.2G  24% /
    tmpfs            7.7G     0  7.7G   0% /dev/shm
    tmpfs            3.1G  1.1M  3.1G   1% /run
    tmpfs            5.0M     0  5.0M   0% /run/lock
    efivarfs         128K  3.4K  125K   3% /sys/firmware/efi/efivars
    /dev/nvme0n1p16  891M   57M  772M   7% /boot
    /dev/nvme0n1p15   98M  6.4M   92M   7% /boot/efi
    tmpfs            1.6G   12K  1.6G   1% /run/user/1000
    /dev/nvme1n1      98G   24K   93G   1% /mnt/newdisk
    ```
### Step 3: Move `/tmp` and install Greengrass Software to the New Disk

1. **Move `/tmp` Directory**:
   - Move the contents of the current `/tmp` directory to the new location:
     ```sh
     sudo mv /tmp/* /mnt/newdisk/tmp
     ```

   - Unmount the `/tmp` directory (if it is in use, you might need to stop services that are using `/tmp`):
     ```sh
     sudo umount /tmp
     ```
   - if `/tmp` is part of the rootfile system then Bind mount the new `/tmp` directory:
      - Rename the original /tmp directory to keep a backup
      ```sh
      sudo mv /tmp /tmp_backup
      rm -rf /tmp
      ```
    - Create a symbolic link:
      ```sh
      ln -s /mnt/newdisk/tmp/ /tmp
      ```
   

2. Create symbolic link to store new greengrass software
   ```sh
   sudo ln -s /mnt/newdisk/greengrass /greengrass
   ```


### Step 4: Configure `/etc/fstab` for Automatic Mounting

1. **Get the UUID of the Disk**:
   - Find the UUID of the new disk:
     ```sh
     sudo blkid /dev/nvme1n1
     ```
      this shows the output something like this
     ```sh
     /dev/nvme1n1: UUID="8ed7081c-c2a3-4c48-a2d6-617d34c07dbd" BLOCK_SIZE="4096" TYPE="ext4"
     ```
2. **Edit `/etc/fstab`**:
   - Open the `/etc/fstab` file in a text editor:
     ```sh
     sudo nano /etc/fstab
     ```
    
3. **Add an Entry for the New Disk and Bind Mounts**:
   - Add a line to the file with the UUID, mount point, filesystem type, and options. For example:
     ```
     UUID=8ed7081c-c2a3-4c48-a2d6-617d34c07dbd /mnt/newdisk ext4 defaults,nofail 0 2
     ```
4. Add lines to bind mount the directories:
   ```sh
    /mnt/newdisk/tmp /tmp none bind 0 0
    /mnt/newdisk/greengrass /greengrass/ none bind 0 0

   ```


5. **Save and Close**:
   - Save the changes and close the editor.

6. **Test the `/etc/fstab` Entry**:
   - Unmount the disk and then remount all filesystems using `fstab` to test the configuration:
     ```sh
     sudo umount /mnt/newdisk
     sudo mount -a
     ```

7. **Verify the Mount**:
   - Check that the disk is mounted correctly again:
     ```sh
     df -h
     ```
8. **Give execution permission to `/mnt/newdisk/tmp`
   ```sh
   chmod a+wrx /mnt/newdisk/tmp
   ```
By following these steps, you can ensure that both the `/tmp` directory and the Greengrass software directory are moved to a new 100GB disk, ensuring adequate storage space for your operations.

## AWS Greegrass Lambda function languages
AWS Greengrass V2 supports Lambda functions written in several programming languages, allowing developers to create and deploy edge applications in their preferred language. The supported programming languages for Greengrass V2 Lambda functions include:

1. **Python**:
   - Python 3.9
   - Python 3.8
   - Python 3.7
   - Python 2.7

2. **Node.js**:
   - Node.js 14.x
   - Node.js 12.x
   - Node.js 10.x

3. **Java**:
   - Java 11
   - Java 8

4. **Go**:
   - Go 1.x

5. **.NET Core**:
   - .NET Core 3.1

6. **Ruby**:
   - Ruby 2.7

7. **Custom Runtimes**:
   - AWS Greengrass V2 also supports custom runtimes, allowing developers to bring their own runtime by specifying an executable or a script to run their functions. This provides flexibility to use languages not natively supported by AWS.

These languages cover a wide range of use cases and enable developers to leverage their existing skills and codebases when working with AWS Greengrass V2.
# Greengrass V2 prerequisites

Please make sure you follow [prerequisite page](https://docs.aws.amazon.com/greengrass/v2/developerguide/getting-started-prerequisites.html)

### Create an Administrator user in IAM in AWS Console
- Create an user with  "AdministratorAccess" policy.
- Follow the prompts to create the user and download the credentials. These will be Access Key and Security Access Key we will use this with AWS CLI

### Setup Python 3.10 

To install Python 3.10 on an aarch64 (ARM64) Ubuntu system, you can follow these steps. This process involves adding the deadsnakes PPA, which contains newer versions of Python that may not be available in the default Ubuntu repositories.

**NOTE**: before following these steps please check if you have python already 
```sh
python --version
```
if python is already installed you need not following python steps for installation. Please follow  below setting Python 3.10 as the Default Python Version (Optional)
#### Step-by-Step Instructions:

1. **Update the System**:
   First, ensure that your package list is up-to-date:
   ```sh
   sudo apt update
   ```

2. **Install Prerequisites**:
   Install the prerequisites for adding new repositories and managing your packages:
   ```sh
   sudo apt install software-properties-common
   ```

3. **Add the deadsnakes PPA**:
   Add the deadsnakes PPA, which contains the latest Python versions:
   ```sh
   sudo add-apt-repository ppa:deadsnakes/ppa
   ```
   also there will be warning something like this 
   ```sh
   Warning: The unit file, source configuration file or drop-ins of apt-news.service changed on disk. Run 'systemctl daemon-reload' to reload units.
   Warning: The unit file, source configuration file or drop-ins of esm-cache.service changed on disk. Run 'systemctl daemon-reload' to reload units.
   ```
   Run the following command 
   ```sh
   systemctl daemon-reload
   ```



4. **Update the Package List Again**:
   After adding the new PPA, update your package list:
   ```sh
   sudo apt update
   ```

5. **Install Python 3.10**:
   Install Python 3.10:
   ```sh
   sudo apt install python3.10
   ```

6. **Verify the Installation**:
   Check the installed Python version to confirm it is installed correctly:
   ```sh
   python3.10 --version
   ```

#### Setting Python 3.10 as the Default Python Version (Optional)

If you want to set Python 3.10 as the default Python version, you can update the alternatives system:

1. **Install the Alternatives System**:
   If not already installed, install the alternatives system:
   ```sh
   sudo apt install python-is-python3
   ```

2. **Update Alternatives to Use Python 3.10**:
   Set Python 3.10 as the default python3:
   ```sh
   sudo update-alternatives --install /usr/bin/python3 python /usr/bin/python3.10 1
   ```


#### Installing Pip for Python 3.10

1. **Install Pip**:
   To install `pip` for Python 3.10, use the following command:
   ```sh
   sudo apt install python3.10-distutils
   curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.10
   ```

2. **Verify Pip Installation**:
   Check the installed pip version:
   ```sh
   pip --version
   ```

By following these steps, you can successfully install Python 3.10 on your aarch64 Ubuntu system and optionally set it as the default Python version.

### Install AWS CLI
- make sure that glibc 2.25 or higher version is available by running following command
  ```sh
  ldd --version
  ```
  normally it should print version higher than 2.25 if not follow the instruction below
  ```sh
   sudo apt update
   sudo apt upgrade libc6
   ldd --version
 ```   
- make sure following commands works
 ```sh
    groff
    less
    unzip
```
if unzip doesnt work install unzip with
```sh
 sudo apt install unzip
```
change directory to your home `cd ~` 
[Reference](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"

unzip awscliv2.zip
sudo ./aws/install
```
Now configure aws profile with the Admin credentials you have created earlier
```sh
aws configure --profile <yourEnvironment>-<yourAdminName>

AWS Access Key ID [None]: <your Access Key ID for admin account in your environment>
AWS Secret Access Key [None]: <your sccret Access Key for admin>
Default region name [None]: ap-southeast-2
Default output format [None]: json
```
Varify the version of AWS CLI
```sh
aws --version
```
This produces the output (very AWS CLI version v2.1.11 or higher)
```sh
aws-cli/2.15.51 Python/3.11.8 Linux/6.8.0-1008-aws exe/aarch64.ubuntu.24
```

Update default profile in environment variable `AWS_PROFILE` set this in `/etc/profile'

**NOTE**
also if you are running commands using `sudo bash` prefer running `sudo -E bash` You can preserve the environment variables when using sudo by using the -E option:

Follow the following:
[Install Java or openjdk](#install-java-or-openjdk)

## Why QEMU
This is required to create VM of ARM Linux (Ubuntu xx.xx aarch64) in Host which is  x86_64 based. Following is the answer from `GPT 40`

Creating ARM-based guest VMs on x86-64 hosts can be done using various virtualization tools that support emulation. Here are some popular options:

1. **QEMU (Quick EMUlator)**:
   - **Description**: QEMU is a free and open-source emulator and virtualizer that can perform hardware virtualization. It can emulate a variety of architectures, including ARM on x86-64 hosts.
   - **Pros**: 
     - Highly versatile and supports many architectures.
     - Extensive configuration options for custom setups.
     - Can be integrated with other virtualization tools like KVM (on Linux) for better performance.
   - **Cons**:
     - Can be complex to set up and configure.
     - Performance may be slower compared to native virtualization.

2. **UTM (User-Friendly macOS Virtualization)**:
   - **Description**: UTM is a front-end for QEMU designed for macOS, but it also works on Windows and Linux. It provides a user-friendly interface for creating and managing VMs.
   - **Pros**: 
     - User-friendly interface.
     - Easy to set up and manage VMs.
   - **Cons**:
     - Primarily designed for macOS; Windows and Linux support might not be as robust.
     - Relies on QEMU, so it shares some of the same performance limitations.

3. **Parallels Desktop (for macOS)**:
   - **Description**: Parallels Desktop is a popular virtualization tool for macOS that supports running various operating systems, including ARM-based VMs on Apple Silicon Macs.
   - **Pros**:
     - Optimized for macOS and provides good performance on Apple Silicon.
     - User-friendly interface.
   - **Cons**:
     - Paid software with a subscription model.
     - Limited to macOS hosts.

4. **VMware Fusion (for macOS)**:
   - **Description**: VMware Fusion is another virtualization solution for macOS that supports running ARM-based VMs on Apple Silicon.
   - **Pros**:
     - Robust feature set and good performance.
     - Well-integrated with macOS.
   - **Cons**:
     - Paid software.
     - Limited to macOS hosts.

5. **Hyper-V (Windows 10/11 Pro and Enterprise)**:
   - **Description**: Hyper-V is a native hypervisor from Microsoft for Windows. While it doesn't natively support ARM guest VMs, you can use it with nested virtualization and QEMU for ARM emulation.
   - **Pros**:
     - Integrated into Windows, no additional installation required.
     - Good performance for x86-64 VMs.
   - **Cons**:
     - Does not natively support ARM emulation; requires additional setup with QEMU.
     - More complex setup for ARM emulation.

6. **VirtualBox**:
   - **Description**: VirtualBox is a free and open-source virtualization tool from Oracle. It supports a wide range of operating systems as guest VMs.
   - **Pros**:
     - Free and open-source.
     - Cross-platform support (Windows, macOS, Linux).
   - **Cons**:
     - Does not natively support ARM guest VMs; requires QEMU for ARM emulation.
     - Performance may be limited for ARM emulation.

### Recommended Approach: QEMU

Given the goal of creating ARM-based Ubuntu 18.04 aarch64 guest VMs on an x86-64 host, QEMU is the most versatile and widely used tool. Here’s a brief guide to setting up an ARM VM with QEMU on an x86-64 host:

 **Install QEMU**:
   - On **Ubuntu**:
     ```bash
     sudo apt-get install qemu-system-arm
     ```
   - On **Windows** using Chocolatey:
     ```powershell
     choco install qemu
     ```


I have previously tried to create QEMU Guest Ubuntu 18.04 image with bridge Networking in my Host Ubuntu 22.04 using netplan and then with NetworkManager I faced lot of problem in setting it up

I have use [ChatGPT 40](https://chatgpt.com/) to get instruction but those instructions were not working. When I setup bridge my whole wifi or ethernet stops working 

Same happend when I use Host as Windows 11 machine with bridge networking for which `chatgpt` gave instruction to install openvpn as virtual adapter and bridge it with Wifi adapter, which also failed. So ultimately I am Including instruction that are working for me with NAT network bridge on Windows 11. 

- Q. Why I Chose Windows 11
- A. Well its your choice you can follow same instruction with QEMU installed on the Ubuntu 22.04, well in my case I have access to 5GHz wifi in Windows, my Wifi Adapter didnt work in 6GHz mode. I tried installing driver from source code but it never picked up my 5GHz SSID.

# Setting Up ARM-based Ubuntu 18.04 for AWS Greengrass Core on Windows 11

In this guide, we'll walk through the steps to set up an ARM-based Ubuntu 18.04 virtual machine on Windows 11 using QEMU. We'll configure the VM for OpenSSH access and prepare it for experimenting with AWS Greengrass Core V2, including manual installation and fleet provisioning. Additionally, we'll cover how to clone the base VM for multiple instances.

**NOTE** You should have the Administrative privileges in your Windows 11 machine to perform following steps

## Step 1: Install Chocolatey on Windows 11

First, we need to install Chocolatey, a package manager for Windows that simplifies software installation.

1. **Open PowerShell as Administrator**:
   - Press `Win + X` and select `Windows PowerShell (Admin)`.

2. **Run the following command to install Chocolatey**:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    ```
## Step 2: Install QEMU and OpenVPN using Chocolatey

1. **Install QEMU**:
   ```powershell
   choco install qemu -y
   ```

2. **Install OpenVPN**:
   ```powershell
   choco install openvpn -y
   ```

3. **Add QEMU to the System Path**:
   - Open PowerShell and run:
     ```powershell
     $env:Path += ";C:\Program Files\qemu"
     [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
     ```

## Step 3: Download and Use `QEMU_EFI.fd`
 - **NOTE** Follow this step if you want to otherwise I have included this file in github 
  
1. **Download the OVMF Package**:
   - Visit the [Fedora Project's OVMF package page](https://www.kraxel.org/repos/jenkins/edk2/).
   - Download the appropriate `.rpm` package (e.g., `edk2-aarch64-<version>.rpm`).

2. **Extract `QEMU_EFI.fd`**:
   - Use `7-Zip` or another extraction tool to open the `.rpm` file.
   - Navigate to the `usr/share/edk2` or similar directory and extract `QEMU_EFI.fd`.

3. **Move `QEMU_EFI.fd` to Your QEMU Directory**:
   - Place the `QEMU_EFI.fd` file in a directory such as `D:\arm-ubuntu-qemu`.

## Step 4: Create the Ubuntu 18.04 ARM aarch64 Base Image

1. **Create a Base Image**:
   ```powershell
   qemu-img create -f qcow2 D:\arm-ubuntu-qemu\ubuntu-arm64.qcow2 20G
   ```

2. **Download Ubuntu 18.04 ARM64 ISO**:
   - Download the Ubuntu 18.04 ARM64 server ISO from the [official Ubuntu releases page](https://releases.ubuntu.com/18.04/).

3. **Install Ubuntu 18.04**:
   ```powershell
   qemu-system-aarch64 -name ubuntu-arm64 -machine virt -cpu cortex-a53 -smp 2 -m 2048 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64.qcow2,id=hd0,format=qcow2 -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net0 -netdev user,id=net0 -cdrom D:\path\to\ubuntu-18.04.5-live-server-arm64.iso -boot d -nographic -serial mon:stdio
   ```
   - Follow the installation steps to install Ubuntu 18.04.

## Step 5: Configure OpenSSH in the Guest VM

1. **Login to the Guest VM Console**.
2. **Install OpenSSH Server**:
   ```bash
   sudo apt update
   sudo apt install openssh-server
   ```

3. **Enable and Start SSH Service**:
   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

4. **Configure Netplan for DHCP**:
   ```bash
   sudo nano /etc/netplan/01-netcfg.yaml
   ```

   Update the file with:
   ```yaml
   network:
     version: 2
     ethernets:
       eth0:
         dhcp4: true
   ```

5. **Apply Netplan Configuration**:
   ```bash
   sudo netplan apply
   ```

## Step 6: Clone the Base VM for Multiple Instances

TODO: Tweaking of the Kernel parameters

1. **Create a Clone of the Base Image**:
   ```powershell
   qemu-img create -f qcow2 -F qcow2 -b D:\arm-ubuntu-qemu\ubuntu-arm64.qcow2 D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2
   ```

2. **Run the Cloned VM**:
   ```powershell
   qemu-system-aarch64 -name ubuntu-arm64 -machine virt -cpu cortex-a53 -smp 6 -m 6177 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2,id=hd0,format=qcow2 -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-gpu -nographic -serial mon:stdio
   ```

3. **SSH into the Cloned VM**:
   ```powershell
   ssh -p 2222 your_username@localhost
   ```

**NOTE**: I have precreated the qcow2 image and included this in github account TODO: install on some server and give path




### Kernel tuning for Greengrass Core V2 
   This step is required as specified in AWS documentation for [Lambda Function Requirement](https://docs.aws.amazon.com/greengrass/v2/developerguide/setting-up.html#greengrass-v2-lambda-requirements)

Please make sure of executing the following commands in your Guest VM shell answers all of `y` or `m` If thats the case you need not recompile kernel only you need to set grub configuration. 


```bash
grep CONFIG_IPC_NS /boot/config-$(uname -r)
grep CONFIG_UTS_NS /boot/config-$(uname -r)
grep CONFIG_USER_NS /boot/config-$(uname -r)
grep CONFIG_PID_NS /boot/config-$(uname -r)
grep CONFIG_CGROUP_DEVICE /boot/config-$(uname -r)
grep CONFIG_CGROUPS /boot/config-$(uname -r)
grep CONFIG_MEMCG /boot/config-$(uname -r)
grep CONFIG_POSIX_MQUEUE /boot/config-$(uname -r)
grep CONFIG_OVERLAY_FS /boot/config-$(uname -r)
grep CONFIG_HAVE_ARCH_SECCOMP_FILTER /boot/config-$(uname -r)
grep CONFIG_SECCOMP_FILTER /boot/config-$(uname -r)
grep CONFIG_KEYS /boot/config-$(uname -r)
grep CONFIG_SECCOMP /boot/config-$(uname -r)
grep CONFIG_SHMEM /boot/config-$(uname --r)
```
In my case the default kernel `4.15.0-213-generic` supports all these parameters, so I am skipping it to [Step 7: Configure GRUB for cgroup Settings](#step-7-configure-grub-for-cgroup-settings)
My output of Above commands
```bash
$ grep CONFIG_IPC_NS /boot/config-$(uname -r)
CONFIG_IPC_NS=y
$ grep CONFIG_UTS_NS /boot/config-$(uname -r)
CONFIG_UTS_NS=y
$ grep CONFIG_USER_NS /boot/config-$(uname -r)
CONFIG_USER_NS=y
$ grep CONFIG_PID_NS /boot/config-$(uname -r)
CONFIG_PID_NS=y
$ grep CONFIG_CGROUP_DEVICE /boot/config-$(uname -r)
CONFIG_CGROUP_DEVICE=y
$ grep CONFIG_CGROUPS /boot/config-$(uname -r)
CONFIG_CGROUPS=y
$ grep CONFIG_MEMCG /boot/config-$(uname -r)
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
# CONFIG_MEMCG_SWAP_ENABLED is not set
$ grep CONFIG_POSIX_MQUEUE /boot/config-$(uname -r)
CONFIG_POSIX_MQUEUE=y
CONFIG_POSIX_MQUEUE_SYSCTL=y
$ grep CONFIG_OVERLAY_FS /boot/config-$(uname -r)
CONFIG_OVERLAY_FS=m
# CONFIG_OVERLAY_FS_REDIRECT_DIR is not set
CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW=y
# CONFIG_OVERLAY_FS_INDEX is not set
$ grep CONFIG_HAVE_ARCH_SECCOMP_FILTER /boot/config-$(uname -r)
CONFIG_HAVE_ARCH_SECCOMP_FILTER=y
$ grep CONFIG_SECCOMP_FILTER /boot/config-$(uname -r)
CONFIG_SECCOMP_FILTER=y
$ grep CONFIG_KEYS /boot/config-$(uname -r)
CONFIG_KEYS=y
CONFIG_KEYS_COMPAT=y
$ grep CONFIG_SECCOMP /boot/config-$(uname -r)
CONFIG_SECCOMP_FILTER=y
CONFIG_SECCOMP=y
$ grep CONFIG_SHMEM /boot/config-$(uname --r)
CONFIG_SHMEM=y
```
You can download the kernel source directly from the Ubuntu repositories. This approach ensures you get the correct version of the kernel that matches your current installation. Here are the steps to download and compile the kernel from the Ubuntu repository:

To download the kernel source from the Ubuntu repositories, you need to enable the source code repositories in your `sources.list`. Here's how to do it:

### Step-by-Step Guide to Enable Source Repositories and Download Kernel Source
Let's take a different approach to enable the necessary kernel configurations. We can directly edit the `.config` file to set the required options. Here are the steps to do that:

### Step-by-Step Guide to Manually Edit the Kernel Configuration

#### Step 1: Download the Kernel Source Code

1. **Enable Source Repositories**:
   ```bash
   sudo nano /etc/apt/sources.list
   ```

   Uncomment the lines starting with `deb-src` for your distribution (e.g., `bionic` for Ubuntu 18.04). The lines should look similar to this:
   ```plaintext
   deb-src http://archive.ubuntu.com/ubuntu/ bionic main restricted
   deb-src http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted
   deb-src http://archive.ubuntu.com/ubuntu/ bionic universe
   deb-src http://archive.ubuntu.com/ubuntu/ bionic-updates universe
   deb-src http://archive.ubuntu.com/ubuntu/ bionic multiverse
   deb-src http://archive.ubuntu.com/ubuntu/ bionic-updates multiverse
   deb-src http://archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
   ```

2. **Update the package lists**:
   ```bash
   sudo apt update
   ```

3. **Install the required tools**:
   ```bash
   sudo apt install fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
   ```

4. **Download the kernel source**:
   ```bash
   mkdir ~/kernelbuild
   cd ~/kernelbuild
   apt source linux-image-$(uname -r)
   ```

5. **Navigate to the kernel source directory**:
   ```bash
   cd linux-*
   ```

#### Step 2: Copy Current Kernel Configuration

Use the current kernel configuration as a starting point:

```bash
cp /boot/config-$(uname -r) .config
```

#### Step 3: Manually Edit the `.config` File

1. **Open the `.config` file for editing**:
   ```bash
   nano .config
   ```

2. **Add or modify the following lines to enable the required configurations**:

   - **Namespaces**:
     ```plaintext
     CONFIG_IPC_NS=y
     CONFIG_UTS_NS=y
     CONFIG_USER_NS=y
     CONFIG_PID_NS=y
     ```

   - **Cgroups**:
     ```plaintext
     CONFIG_CGROUP_DEVICE=y
     CONFIG_CGROUPS=y
     CONFIG_MEMCG=y
     ```

   - **Others**:
     ```plaintext
     CONFIG_POSIX_MQUEUE=y
     CONFIG_OVERLAY_FS=m
     CONFIG_HAVE_ARCH_SECCOMP_FILTER=y
     CONFIG_SECCOMP_FILTER=y
     CONFIG_KEYS=y
     CONFIG_SECCOMP=y
     CONFIG_SHMEM=y
     ```

  When CONFIG_OVERLAY_FS=m is set, it means that the Overlay filesystem support is built as a module. This module can be loaded and unloaded dynamically, rather than being built directly into the kernel.

3. **Save and close the file** (in nano, press `Ctrl + O` to save and `Ctrl + X` to exit).

#### Step 4: Compile and Install the Kernel

1. **Compile the kernel**:
   ```bash
   make -j$(nproc)
   ```

2. **Install the modules**:
   ```bash
   sudo make modules_install
   ```

3. **Install the kernel**:
   ```bash
   sudo make install
   ```

#### Step 5: Update Bootloader

1. **Update the initramfs and GRUB**:
   ```bash
   sudo update-initramfs -c -k $(make kernelrelease)
   sudo update-grub
   ```


- Load the Overlay Module:
After rebooting into the new kernel, you need to load the module. You can load it manually or ensure it is loaded at boot time
- To load at boot time:
Create a file in `/etc/modules-load.d/` to automatically load the overlay module at boot.
```bash
echo "overlay" | sudo tee /etc/modules-load.d/overlay.conf
```
2. **Reboot the system**:
   ```bash
   sudo reboot
   ```
#### Step 6: Verify the Configuration

After rebooting, verify that the new kernel options are enabled:

```bash
grep CONFIG_IPC_NS /boot/config-$(uname -r)
grep CONFIG_UTS_NS /boot/config-$(uname -r)
grep CONFIG_USER_NS /boot/config-$(uname -r)
grep CONFIG_PID_NS /boot/config-$(uname -r)
grep CONFIG_CGROUP_DEVICE /boot/config-$(uname -r)
grep CONFIG_CGROUPS /boot/config-$(uname -r)
grep CONFIG_MEMCG /boot/config-$(uname -r)
grep CONFIG_POSIX_MQUEUE /boot/config-$(uname -r)
grep CONFIG_OVERLAY_FS /boot/config-$(uname -r)
grep CONFIG_HAVE_ARCH_SECCOMP_FILTER /boot/config-$(uname -r)
grep CONFIG_SECCOMP_FILTER /boot/config-$(uname -r)
grep CONFIG_KEYS /boot/config-$(uname -r)
grep CONFIG_SECCOMP /boot/config-$(uname -r)
grep CONFIG_SHMEM /boot/config-$(uname --r)
```

Each command should return the configuration option with `=y` indicating it is enabled.

### Step 7: Configure GRUB for cgroup Settings

1. **Edit the GRUB configuration file**:
   ```bash
   sudo nano /etc/default/grub
   ```

2. **Modify the `GRUB_CMDLINE_LINUX_DEFAULT` line** to include the desired kernel parameters:
   ```plaintext
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash cgroup_enable=memory cgroup_memory=1 systemd.unified_cgroup_hierarchy=0"
   ```

3. **Save and close the file** (in nano, press `Ctrl + O` to save and `Ctrl + X` to exit).

4. **Update GRUB**:
   ```bash
   sudo update-grub
   ```

5. **Reboot the system**:
   ```bash
   sudo reboot
   ```

6. **Verify the kernel parameters**:
   ```bash
   cat /proc/cmdline
   ```

   You should see the parameters `cgroup_enable=memory`, `cgroup_memory=1`, and `systemd.unified_cgroup_hierarchy=0` in the output.

By following these steps, you can configure your system to enable memory cgroups, set the cgroup hierarchy to v1, and ensure that the required kernel parameters are enabled. This setup will allow you to support applications like AWS Greengrass Core V2 on your Ubuntu 18.04 aarch64 system.


## Step 7: Verify following commands else install them

- Your device must have the `mkfifo` shell command
  
  Its usually there in Ubuntu 18.04 aarch64
- check `useradd`, `groupadd` and `usermod` are working
  
  They are usually there in Ubuntu 18.04 aarch6
- Validate all the [Greengrass Core V2 requirements](https://docs.aws.amazon.com/greengrass/v2/developerguide/setting-up.html#greengrass-v2-requirements)
  
#### Check glibc version
Run the `ldd` Command:
Execute the following command to check the glibc version:
```bash
ldd --version
```
Check the output
```bash
ldd (Ubuntu GLIBC 2.27-3ubuntu1.6) 2.27
Copyright (C) 2018 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Written by Roland McGrath and Ulrich Drepper
```
#### The /tmp directory must be mounted with exec permissions.
If `/tmp` is not separately mounted ensure that root filesystem doesnt have `noexec` option set

Run the following command to check the current mount options for the root filesystem (/):
Example output might look like this:
```plaintext
/dev/sda1 on / type ext4 (rw,relatime,data=ordered)
```

#### Install Java or openjdk
Check Java Version:
```bash
java -version
```
If you're output looks something like this
```plaintext
Command 'java' not found, but can be installed with:

sudo apt install default-jre
sudo apt install openjdk-11-jre-headless
sudo apt install openjdk-8-jre-headless
```

#### apt_pkg not found issue 

**NOTE** if you get get error like this 
```plaintext
Traceback (most recent call last):
  File "/usr/lib/command-not-found", line 28, in <module>
    from CommandNotFound import CommandNotFound
  File "/usr/lib/python3/dist-packages/CommandNotFound/CommandNotFound.py", line 19, in <module>
    from CommandNotFound.db.db import SqliteDatabase
  File "/usr/lib/python3/dist-packages/CommandNotFound/db/db.py", line 5, in <module>
    import apt_pkg
ModuleNotFoundError: No module named 'apt_pkg'
```

Then you have some problem in the python installation follow these steps
```bash
 ls /usr/lib/python3/dist-packages/apt_pkg*.so
 ```
 if you get the output like following
 ```plaintext
 /usr/lib/python3/dist-packages/apt_pkg.cpython-312-aarch64-linux-gnu.so
 ```
 Then create a symbolic link 
 ```bash
 sudo ln -s /usr/lib/python3/dist-packages/apt_pkg.cpython-312-aarch64-linux-gnu.so /usr/local/lib/python3.10/dist-packages/apt_pkg.so
 ```
 Above instruction are for python 3.10 only please correct your path as per your python version now you can see


Install Java with following command
```bash
sudo apt install openjdk-8-jre
```
Verify the Installation:
```bash
java -version
```
Ensure the output shows Java version 1.8 or greater.
Set JAVA_HOME and Update PATH
Find the Java Installation Path:
```bash
update-alternatives --config java
```
This command lists all installed Java versions and their paths.
```plaintext
There is only one alternative in link group java (providing /usr/bin/java): /usr/lib/jvm/java-8-openjdk-arm64/jre/bin/java
Nothing to configure.
```

Set JAVA_HOME Environment Variable:
```bash
sudo nano /etc/profile.d/java.sh
```
Add the Following Lines:
```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64/jre
export PATH=$JAVA_HOME/bin:$PATH
````

Save and Close the File:
Press `Ctrl + O` to save and `Ctrl + X` to exit.

Make the Script Executable:

```bash
sudo chmod +x /etc/profile.d/java.sh
```
Reload the Profile:
```bash
source /etc/profile.d/java.sh
```
Verify the Environment Variable:
```bash
echo $JAVA_HOME
echo $PATH
```
- Additional Requirements for Greengrass Core
  
In addition to Java, ensure that you meet other prerequisites for AWS IoT Greengrass Core on Ubuntu 18.04 aarch64:

- Docker (optional): If you plan to run Lambda functions in Docker containers.
  ```bash
  sudo apt install docker.io
  ```
AWS IoT Greengrass Core supports Python 3.7 and 3.8 for running Lambda functions as of the latest official documentation. While Python 3.10 might work for your general development needs, it's important to use the supported versions to ensure compatibility and support from AWS.

#### Reasons to Use Supported Versions (Python 3.7 or 3.8)

1. **Compatibility**: AWS IoT Greengrass Core is tested and validated with specific Python versions. Using a supported version ensures that all features and functionalities work as expected.
2. **Support**: If you encounter issues while using an unsupported version, you might not receive official support from AWS.
3. **Stability**: Supported versions are typically more stable and have fewer unknown issues within the context of AWS IoT Greengrass.

#### Installing Python 3.8 on Ubuntu 18.04

Here are the steps to install Python 3.8 on Ubuntu 18.04:

1. **Update the Package List**:
   ```bash
   sudo apt update
   ```

2. **Install the `software-properties-common` Package**:
   ```bash
   sudo apt install software-properties-common
   ```

3. **Add the Deadsnakes PPA**:
   The Deadsnakes PPA contains newer Python versions for older Ubuntu releases.
   ```bash
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt update
   ```

4. **Install Python 3.8**:
   ```bash
   sudo apt install python3.8
   ```

5. **Verify the Installation**:
   ```bash
   python3.8 --version
   ```

   You should see output similar to:
   ```plaintext
   Python 3.8.0
   ```

6. **Set Up Python 3.8 as Default (Optional)**:
   If you want to make Python 3.8 the default python3 version, you can update the alternatives:

   ```bash
   sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1
   sudo update-alternatives --config python
   ```

#### Installing Python Packages

You might also need `pip` for managing Python packages:

1. **Install `pip` for Python 3.8**:
   ```bash
   sudo apt install python3.8-venv python3.8-dev python3-pip
   ```

2. **Verify `pip` Installation**:
   ```bash
   pip3 --version
   ```

   Ensure `pip` is pointing to Python 3.8.

   something like this
   ```plaintext
   pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.8)
   ```
#### Summary

While Python 3.10 may work for your projects, using Python 3.7 or 3.8 ensures compatibility with AWS IoT Greengrass Core. Follow the steps above to install Python 3.8 on Ubuntu 18.04, which is a supported version for running Greengrass Lambda functions.

If you still prefer using Python 3.10, ensure thorough testing as you might encounter compatibility issues, and it may not be officially supported by AWS IoT Greengrass Core.  
#### Installing AWS CLI

Yes, the AWS CLI is often required for AWS IoT Greengrass Core manual installation and management. It allows you to configure, deploy, and manage Greengrass groups and devices. Below are the steps to install and configure the AWS CLI on Ubuntu 18.04 aarch64.


##### Step 1: Update Your Package List

Open a terminal and update your package list:

```bash
sudo apt update
```

##### Step 2: Install Required Packages

Install `curl` and `unzip` if they are not already installed:

```bash
sudo apt install curl unzip -y
```

##### Step 3: Download the AWS CLI Installation Script

Download the AWS CLI version 2 installation script:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
```

##### Step 4: Unzip the Installation Script

Unzip the downloaded file:

```bash
unzip awscliv2.zip
```

##### Step 5: Run the Installation Script

Run the AWS CLI installation script:

```bash
sudo ./aws/install
```

##### Step 6: Verify the Installation

Check the AWS CLI version to verify the installation:

```bash
aws --version
```

You should see output similar to:

```plaintext
aws-cli/2.15.57 Python/3.11.8 Linux/4.15.0-213-generic exe/aarch64.ubuntu.18
```

##### Step 7: Configure the AWS CLI

Configure the AWS CLI with your AWS credentials:

```bash
aws configure --profile dev-admin
```

You will be prompted to enter your AWS Access Key ID, Secret Access Key, default region name, and default output format.

Example:

```plaintext
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-west-2
Default output format [None]: json
```
You can check configured profiles with following commands
```bash
aws configure list-profiles
```
Edit your .profile to configure `AWS_PROFILE` environment variable
```bash
vi ~/.profile
```
At the end of the file enter the following 
```bash
export AWS_PROFILE=dev-admin 
```
Save and Exit 

Run the profile file
```bash
. ~/.profile
```
Check by running any aws cli command e.g. `aws s3 ls` 
It should produce some output if yes you are done with AWS CLI configuration


## Running multiple instances of same qcow2 image in QEMU
Copy the `ubuntu-arm64-clone.qcow2` to `ubuntu-arm64-clone-2.qcow2`
Instance 1
```bash
qemu-system-aarch64 -name ubuntu-arm64-1 -machine virt -cpu cortex-a53 -smp 6 -m 6177 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2,id=hd0,format=qcow2 -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-gpu -nographic -serial mon:stdio
```




Instance 2
```bash
qemu-system-aarch64 -name ubuntu-arm64-2 -machine virt -cpu cortex-a53 -smp 6 -m 6177 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64-clone-2.qcow2,id=hd0,format=qcow2,snapshot=on -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net1,mac=52:54:00:12:34:57 -netdev user,id=net1,hostfwd=tcp::2223-:22 -device virtio-gpu -nographic -serial mon:stdio
```

Explanation of Changes
- **Unique MAC Addresses**: Each instance has a unique MAC address to avoid network conflicts.
- **Different Port Forwarding**: Each instance uses a different port for SSH forwarding (e.g., 2222 for the first instance and 2223 for the second instance).
- **Snapshot Mode**: Using snapshot=on ensures that changes are not written to the base image, making it safer to run multiple instances concurrently.
## Step 8: Experiment with AWS Greengrass Core V2

1. **Manual Installation of Greengrass Core V2**:
   - please check these instructions with install and uninstall shell script in [GGCV2-manual-install](GGCV2-manual-install.md)
    - This is based on  [AWS Greengrass Core V2 installation guide](https://docs.aws.amazon.com/greengrass/v2/developerguide/manual-installation.html) to manually install Greengrass Core V2 on your VM.
   
   

1. **Experiment with Fleet Provisioning**:
   - Use the [AWS IoT Greengrass V2 Fleet Provisioning guide](https://docs.aws.amazon.com/greengrass/v2/developerguide/fleet-provisioning.html) to set up fleet provisioning for your VM instances.
   -  **Please tune to this GitHub post I will keep you posted around this**

## Summary

- **Installation of Chocolatey** on Windows 11.
- **Installation of QEMU and OpenVPN** via Chocolatey.
- **Download and use of QEMU_EFI.fd**.
- **Creation of an Ubuntu 18.04 ARM aarch64 base image**.
- **Configuration of OpenSSH** in the guest VM.
- **Cloning the base VM** for multiple instances.
- **Experiments with AWS Greengrass Core V2**.

By following these steps, you can create and run an Ubuntu 18.04 ARM aarch64 guest VM on Windows 11 using QEMU with NAT networking, set up SSH access, and prepare the VM for various AWS Greengrass Core V2 experiments.

Feel free to customize this blog post further to suit your style and add any additional details or images that might help your readers.
