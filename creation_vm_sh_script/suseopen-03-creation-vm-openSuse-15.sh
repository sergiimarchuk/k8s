#!/bin/bash

# Path to openSUSE cloud image
IMAGE_PATH="/root/creation_vm/openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.qcow2"

echo "=== Automated openSUSE Leap 15.6 Cloud-Init VM Creation ==="
echo ""

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Cloud image not found at $IMAGE_PATH"
    echo ""
    echo "Download it with:"
    echo "cd /root/creation_vm"
    echo "wget https://download.opensuse.org/distribution/leap/15.6/appliances/openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.qcow2"
    exit 1
fi

read -p "Enter VM ID (e.g., 920): " VMID
read -p "Enter VM Name (e.g., opensuse-vm-01): " VMNAME
read -p "Enter Memory in MB (default 2048): " MEMORY
MEMORY=${MEMORY:-2048}
read -p "Enter CPU Cores (default 2): " CORES
CORES=${CORES:-2}
read -p "Enter Disk Size in GB (default 32): " DISKSIZE
DISKSIZE=${DISKSIZE:-32}
read -sp "Enter root password: " PASSWORD
echo ""

echo ""
echo "Creating VM with:"
echo "  ID: $VMID"
echo "  Name: $VMNAME"
echo "  Memory: $MEMORY MB"
echo "  Cores: $CORES"
echo "  Disk: ${DISKSIZE}G"
echo "  OS: openSUSE Leap 15.6 (Cloud-Init)"
echo ""

read -p "Proceed? (y/n): " CONFIRM

if [ "$CONFIRM" = "y" ]; then
    echo "Creating VM $VMID..."
    
    # Create VM
    qm create $VMID \
      --name $VMNAME \
      --memory $MEMORY \
      --cores $CORES \
      --sockets 1 \
      --cpu host \
      --numa 0 \
      --ostype l26 \
      --scsihw virtio-scsi-single \
      --net0 virtio,bridge=vmbr0,firewall=1 \
      --agent enabled=1
    
    echo "Importing cloud image disk..."
    # Import the cloud image
    qm importdisk $VMID $IMAGE_PATH local-lvm
    
    echo "Configuring disk and boot..."
    # Attach the imported disk
    qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
    
    # Set boot order
    qm set $VMID --boot order=scsi0
    
    # Add Cloud-Init drive
    qm set $VMID --ide2 local-lvm:cloudinit
    
    # Add serial console for access
    qm set $VMID --serial0 socket --vga serial0
    
    # Configure Cloud-Init settings
    echo "Configuring Cloud-Init..."
    
    # Get IP address
    read -p "Enter IP address (default: 192.168.100.$((VMID))): " IPADDR
    IPADDR=${IPADDR:-192.168.100.$VMID}
    
    qm set $VMID --ciuser root
    qm set $VMID --cipassword "$PASSWORD"
    qm set $VMID --ipconfig0 ip=$IPADDR/24,gw=192.168.100.108
    qm set $VMID --nameserver "8.8.8.8 1.1.1.1"
    
    # Add SSH key if exists
    if [ -f ~/.ssh/id_rsa.pub ]; then
        qm set $VMID --sshkeys ~/.ssh/id_rsa.pub
        echo "✓ SSH key added"
    fi
    
    # Resize disk to requested size
    # openSUSE cloud image is smaller (~200MB), so we resize more
    CURRENT_SIZE=1  # Approximate current size in GB
    if [ "$DISKSIZE" -gt "$CURRENT_SIZE" ]; then
        RESIZE=$((DISKSIZE - CURRENT_SIZE))
        echo "Resizing disk to ${DISKSIZE}G..."
        qm resize $VMID scsi0 +${RESIZE}G
    fi
    
    echo ""
    echo "✓ VM $VMNAME created successfully!"
    echo "✓ Config: /etc/pve/qemu-server/${VMID}.conf"
    echo ""
    echo "NOTE: openSUSE uses different tools than Ubuntu:"
    echo "  - Package manager: zypper (not apt)"
    echo "  - Firewall: firewalld (not ufw)"
    echo "  - Network: wicked or NetworkManager"
    echo ""
    
    read -p "Start VM now? (y/n): " START
    if [ "$START" = "y" ]; then
        qm start $VMID
        echo "✓ VM $VMID started!"
        echo ""
        echo "VM will be ready in ~30-60 seconds"
        echo "Login: root / [your password]"
        echo "IP: $IPADDR"
        echo ""
        echo "Access methods:"
        echo "  SSH: ssh root@$IPADDR"
        echo "  Console: qm terminal $VMID"
        echo ""
        echo "After login, install guest agent:"
        echo "  zypper refresh"
        echo "  zypper install -y qemu-guest-agent"
        echo "  systemctl enable --now qemu-ga"
    fi
fi
