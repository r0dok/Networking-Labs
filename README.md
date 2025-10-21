# Network Infrastructure Labs

Production-tested configs from real lab implementations. VLAN routing, automation, multi-vendor setups.

---

## Structure
```
network-infrastructure-labs/
├── configs/
│   ├── lab1/
│   │   ├── pfsense-routes.md          → pfSense routing config
│   │   ├── cisco-switch.txt           → Cisco VLAN trunk setup
│   │   └── windows-dhcp.md            → Windows Server DHCP scopes
│   ├── lab2/
│   │   ├── cisco-vlan-config.txt      → Cisco 4-VLAN setup
│   │   └── raspberry-pi-setup.md      → Pi router configuration
│   └── lab3/
│       └── generated-vlan-config.txt  → Auto-generated 200 VLAN config
├── scripts/
│   ├── vlan-mass-create.sh            → Creates 200 VLANs via SSH
│   ├── dhcp-mass-config.sh            → Generates dnsmasq pools
│   └── test-connectivity.sh           → Tests all VLAN gateways
└── docs/
    └── troubleshooting.md             → Common issues + solutions
```

**Quick links:**
- [Lab 1 configs](configs/lab1/) | [Lab 2 configs](configs/lab2/) | [Lab 3 configs](configs/lab3/)
- [Automation scripts](scripts/) | [Troubleshooting](docs/troubleshooting.md)

---

## Lab 1: Inter-VLAN Routing with pfSense

**Setup:**
- Network A (VLAN 10): 10.10.10.0/24 - Windows Server DNS/DHCP
- Network B (VLAN 20): 10.20.20.0/24 - isolated
- pfSense routes between them with NAT

DHCP relay lets Network B get IPs from Windows Server in Network A.
```bash
# pfSense static route
10.20.20.0/24 via 193.191.150.57

# Cisco trunk config
interface gigabitEthernet 0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20
```

**Gotchas:**
- NAT is bidirectional
- DHCP relay needs UDP 67/68 rules
- Set non-default native VLAN on trunks

---

## Lab 2: Raspberry Pi VLAN Router

€35 Pi handling 4 VLANs (192.168.1-4.0/24). Cisco switch does tagging + DHCP, Pi routes between VLANs.
```bash
interface vlan 10
 ip address 192.168.1.5 255.255.255.0
 no shutdown

interface fastEthernet 0/2
 switchport mode trunk
 switchport trunk allowed vlan all
```

Just needs IP forwarding enabled. Good for labs, not production.

---

## Lab 3: 200 VLAN Automation

Automated VLAN 2-201 creation with /28 subnets in 10.0.0.0/8.

**Scripts:**
- `vlan-mass-create.sh` - generates + pushes config via SSH
- `dhcp-mass-config.sh` - creates dnsmasq pools
- `test-connectivity.sh` - pings all gateways

200 VLANs configured in 5 minutes.

---

## Usage
```bash
git clone https://github.com/r0dok/Networking-Labs.git
cd Networking-Labs/scripts
chmod +x *.sh

# Lab 3 automation
sudo ./vlan-mass-create.sh
sudo ./dhcp-mass-config.sh
./test-connectivity.sh
```

---

## Notes

- Backup configs before changes
- Test incrementally
- Document non-obvious settings
- Keep rollback plans
