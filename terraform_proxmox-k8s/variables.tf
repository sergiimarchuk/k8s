# Proxmox connection settings
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox user (e.g., terraform@pve)"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox user password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

# Template settings
variable "template_id" {
  description = "VM ID of the template to clone"
  type        = number
  default     = 9000
}

# Storage and Network
variable "storage" {
  description = "Storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

# VM naming
variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "k8s"
}

# Control Plane settings
variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "control_plane_cores" {
  description = "CPU cores for control plane nodes"
  type        = number
  default     = 2
}

variable "control_plane_memory" {
  description = "Memory in MB for control plane nodes"
  type        = number
  default     = 4096
}

variable "control_plane_disk_size" {
  description = "Disk size in GB for control plane nodes (just number, e.g., '32')"
  type        = string
  default     = "32"
}

# Worker settings
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "worker_cores" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
  default     = 4096
}

variable "worker_disk_size" {
  description = "Disk size in GB for worker nodes (just number, e.g., '32')"
  type        = string
  default     = "32"
}

# SSH Keys
variable "ssh_keys" {
  description = "SSH public key for cloud-init"
  type        = string
  default     = ""
}
