terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true
}

# K8s Control Plane Node(s)
resource "proxmox_virtual_environment_vm" "k8s_control_plane" {
  count       = var.control_plane_count
  name        = "${var.vm_name_prefix}-master-${count.index + 1}"
  node_name   = var.proxmox_node
  
  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.control_plane_cores
    type  = "host"
  }

  memory {
    dedicated = var.control_plane_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = parseint(var.control_plane_disk_size, 10)
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = var.ssh_keys != "" ? [var.ssh_keys] : []
    }
  }

  started = false
}

# K8s Worker Nodes
resource "proxmox_virtual_environment_vm" "k8s_workers" {
  count       = var.worker_count
  name        = "${var.vm_name_prefix}-worker-${count.index + 1}"
  node_name   = var.proxmox_node
  
  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.worker_cores
    type  = "host"
  }

  memory {
    dedicated = var.worker_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = parseint(var.worker_disk_size, 10)
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = var.ssh_keys != "" ? [var.ssh_keys] : []
    }
  }

  started = false
}

# Outputs
output "control_plane_vms" {
  value = {
    for vm in proxmox_virtual_environment_vm.k8s_control_plane :
    vm.name => {
      id = vm.vm_id
      ip = try(vm.ipv4_addresses[1][0], "pending")
    }
  }
  description = "Control plane VM details"
}

output "worker_vms" {
  value = {
    for vm in proxmox_virtual_environment_vm.k8s_workers :
    vm.name => {
      id = vm.vm_id
      ip = try(vm.ipv4_addresses[1][0], "pending")
    }
  }
  description = "Worker VM details"
}
