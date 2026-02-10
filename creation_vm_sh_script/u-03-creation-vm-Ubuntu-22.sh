#!/bin/bash

# Path to your downloaded cloud image
IMAGE_PATH="/root/creation_vm/ubuntu-22.04-server-cloudimg-amd64.img"

echo "=== Automated Ubuntu Cloud-Init VM Creation ==="
echo ""

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Cloud image not found at $IMAGE_PATH"
    exit 1
fi

read -p "Enter VM ID (e.g., 300): " VMID
read -p "Enter VM Name (e.g., test-vm-01): " VMNAME
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
echo "  OS: Ubuntu 22.04 (Cloud-Init)"
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
    
    # Get next available IP (you can customize this)
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
    if [ "$DISKSIZE" -gt 2 ]; then
        RESIZE=$((DISKSIZE - 2))
        echo "Resizing disk to ${DISKSIZE}G..."
        qm resize $VMID scsi0 +${RESIZE}G
    fi
    
    echo ""
    echo "✓ VM $VMNAME created successfully!"
    echo "✓ Config: /etc/pve/qemu-server/${VMID}.conf"
    echo ""
    
    read -p "Start VM now? (y/n): " START
    if [ "$START" = "y" ]; then
        qm start $VMID
        echo "✓ VM $VMID started!"
        echo ""
        echo "VM will be ready in ~30 seconds"
        echo "Login: root / [your password]"
        echo "IP: $IPADDR"
        echo ""
        echo "Access methods:"
        echo "  SSH: ssh root@$IPADDR"
        echo "  Console: qm terminal $VMID"
    fi
fi

