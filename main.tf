module "secmgr" {
  source = "./secrets-manager"
}

resource "ibm_is_vpc" "vpc" {
  name = "vpc-vpnserver"
}

resource "ibm_is_security_group" "sg_all" {
  name = "vpc-sg-all"
  vpc  = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "sg_rule1" {
  group     = ibm_is_security_group.sg_all.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "sg_rule2" {
  group     = ibm_is_security_group.sg_all.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_subnet" "subnet" {
  name                     = "mysubnet-tf"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone_name
  total_ipv4_address_count = 256
}


resource "ibm_is_vpn_server" "example" {
  certificate_crn = module.secmgr.import_cert_server_crn

  client_authentication {
    method        = "certificate"
    client_ca_crn = module.secmgr.import_cert_client_crn
  }

  client_authentication {
    method            = "username"
    identity_provider = "iam"
  }

  client_ip_pool         = "192.168.0.0/16"
  enable_split_tunneling = true
  name                   = "terry-vpn-server"
  port                   = 443
  protocol               = "tcp"
  subnets                = [ibm_is_subnet.subnet.id]
  security_groups        = [ibm_is_security_group.sg_all.id]
}

resource "ibm_is_vpn_server_route" "cse1" {
  vpn_server  = ibm_is_vpn_server.example.id
  destination = "166.8.0.0/14"
  name        = "vpn-server-route-cse1"
}

resource "ibm_is_vpn_server_route" "cse2" {
  vpn_server  = ibm_is_vpn_server.example.id
  destination = "161.26.0.0/16"
  name        = "vpn-server-route-cse2"
}


data "ibm_is_vpn_server_client_configuration" "my_vpn_client_conf" {
  vpn_server = ibm_is_vpn_server.example.id
}

resource "local_file" "my_vpn_client_conf" {
  content  = "${data.ibm_is_vpn_server_client_configuration.my_vpn_client_conf.vpn_server_client_configuration}\ncert ${path.cwd}/import_certs/client_cert.pem\nkey ${path.cwd}/import_certs/client_key.pem"
  filename = "my_vpn_server.ovpn"
}
