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
- 
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

1. **Create a Clone of the Base Image**:
   ```powershell
   qemu-img create -f qcow2 -b D:\arm-ubuntu-qemu\ubuntu-arm64.qcow2 D:\arm-ubuntu-qemu\ubuntu-arm64-clone.qcow2
   ```

2. **Run the Cloned VM**:
   ```powershell
   emu-system-aarch64 -name ubuntu-arm64 -machine virt -cpu cortex-a53 -smp 2 -m 2048 -bios D:\arm-ubuntu-qemu\QEMU_EFI.fd -drive if=none,file=D:\arm-ubuntu-qemu\ubuntu-arm64.qcow2,id=hd0,format=qcow2 -device virtio-blk-device,drive=hd0 -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-gpu -nographic -serial mon:stdio
   ```

3. **SSH into the Cloned VM**:
   ```powershell
   ssh -p 2222 your_username@localhost
   ```

**NOTE**: I have precreated the qcow2 image and included this in github account 


## Step 7: Experiment with AWS Greengrass Core V2

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
```

This markdown version is designed for easy readability and formatting on GitHub. Feel free to adjust and add any additional details or images to enhance your blog post.