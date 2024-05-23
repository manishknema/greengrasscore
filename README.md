# Setting Up ARM-based Ubuntu 18.04 for AWS Greengrass Core
I wanted to see for one project how [AWS Greengrass Core V2](https://docs.aws.amazon.com/greengrass/v2/developerguide/what-is-iot-greengrass.html) is beneficial for local processing and Since most of the IoT Edge devices are based on the ARM architecture and very constraint typically 8-12 GB RAM and 10-100 GB Disk with/without GPU/NPU. I want to test out features of Greengrass before going full blown deployment in actual devices. 

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
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64/jre/bin/
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

## Running multiple instances of same qcow2 image in QEMU
Instance 1
```bash
qemu-system-aarch64 -name ubuntu-arm64-1 -machine virt -cpu cortex-a53 -smp 6 -m 6177 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2,id=hd0,format=qcow2,snapshot=on -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-gpu -nographic -serial mon:stdio
```
Instance 2
```bash
qemu-system-aarch64 -name ubuntu-arm64-2 -machine virt -cpu cortex-a53 -smp 6 -m 6177 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2,id=hd0,format=qcow2,snapshot=on -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net1,mac=52:54:00:12:34:57 -netdev user,id=net1,hostfwd=tcp::2223-:22 -device virtio-gpu -nographic -serial mon:stdio
```

Explanation of Changes
- **Unique MAC Addresses**: Each instance has a unique MAC address to avoid network conflicts.
- **Different Port Forwarding**: Each instance uses a different port for SSH forwarding (e.g., 2222 for the first instance and 2223 for the second instance).
- **Snapshot Mode**: Using snapshot=on ensures that changes are not written to the base image, making it safer to run multiple instances concurrently.
## Step 8: Experiment with AWS Greengrass Core V2

1. **Manual Installation of Greengrass Core V2**:
   - Follow the [AWS Greengrass Core V2 installation guide](https://docs.aws.amazon.com/greengrass/v2/developerguide/manual-installation.html) to manually install Greengrass Core V2 on your VM.
    - **Please tune to this GitHub post I will keep you posted around this**

2. **Experiment with Fleet Provisioning**:
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
