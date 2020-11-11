variable "project_id" {}

provider "google" {
        project = var.project_id
}

module "resource-manager" {
        source = "github.com/adamescamilla/gcp/modules/service"
        project = var.project_id
        service_name = "cloudresourcemanager.googleapis.com"
}

module "iot-resource" {
        source = "github.com/adamescamilla/gcp/modules/service"
        project = var.project_id
        service_name = "cloudiot.googleapis.com"
        depends_on = [
                module.resource-manager,
        ]
}

module "compute-resource" {
        source = "github.com/adamescamilla/gcp/modules/service"
        project = var.project_id
        service_name = "compute.googleapis.com"
        depends_on = [
                module.resource-manager,
        ]
}

module "network" {
        source = "github.com/adamescamilla/gcp/modules/network"
        network_name = "iot-simulator-network"
        subnet_name = "iot-simulator-subnet"
        cidr_range = "10.0.0.0/16"
        depends_on = [
                module.compute-resource,
        ]
}

module "firewall" {
        source = "github.com/adamescamilla/gcp/modules/firewall"
        firewall_name = "iot-simulator-firewall"
        network_link = module.network.network_link
        allow_ports = ["80","443","22"]
}

module "instance" {
        source = "github.com/adamescamilla/gcp/modules/instance"
        instance_name = "iot-simulator-instance"
        instance_type = "f1-micro"
        instance_os = "ubuntu-os-cloud/ubuntu-minimal-1804-lts"
        ssh_user = "ubuntu"
        network_link = module.network.network_link
        subnet_id = module.network.subnet_id
}

output "instance_ip" {
        value = module.instance.nat_ip
}

