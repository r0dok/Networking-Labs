# Network Infrastructure Labs

Real-world VLAN routing, automation, and multi-vendor integration. Production-tested configs from actual lab implementations.

---

## Lab 1: Inter-VLAN Routing with pfSense

Two networks talking through a firewall.

**Setup:**
- Network A (VLAN 10): 10.10.10.0/24 with Windows Server DNS/DHCP
- Network B (VLAN 20): 10.20.20.0/24 isolated network
- pfSense routing + NAT between them

The tricky part: DHCP relay so Network B gets IPs from Windows Server in Network A.

**Key config:**
```bash
# pfSense static route
10.20.20.0/24 via 193.191.150.57

# Cisco trunk
interface gigabitEthernet 0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20
```

**Lessons:** 
- NAT is bidirectional - don't forget return traffic
- DHCP relay needs UDP 67/68 firewall rules
- Always set non-default native VLAN on trunks

---

## Lab 2: Raspberry Pi VLAN Router

Can a €35 Pi route VLANs? Yes.

**What I built:**
- 4 VLANs (192.168.1-4.0/24)
- Pi on trunk handling inter-VLAN routing
- Cisco switch doing VLAN tagging + DHCP

```bash
interface vlan 10
 ip address 192.168.1.5 255.255.255.0
 no shutdown

interface fastEthernet 0/2
 switchport mode trunk
 switchport trunk allowed vlan all
```

Pi just needs IP forwarding enabled. Works great for learning. Not for production.

---

## Lab 3: 200 VLAN Automation

Instructor: "Configure 200 VLANs by next week"  
Me: *writes bash scripts*

**Specs:**
- VLANs 2-201
- 10.0.0.0/8 with /28 subnets
- Automated: VLAN creation, DHCP pools, testing

**Three scripts:**
1. `vlan-mass-create.sh` - generates + pushes Cisco config via SSH/Expect
2. `dhcp-mass-config.sh` - creates dnsmasq pools for all VLANs
3. `test-connectivity.sh` - pings every gateway

200 VLANs configured in 5 minutes.

---

## Repository Structure

```
network-infrastructure-labs/
├── README.md
├── configs/
│   ├── lab1/
│   │   ├── pfsense-routes.txt
│   │   ├── cisco-switch.txt
│   │   └── windows-dhcp.txt
│   ├── lab2/
│   │   ├── cisco-vlan-config.txt
│   │   └── raspberry-pi-setup.md
│   └── lab3/
│       └── generated-vlan-config.txt
├── scripts/
│   ├── vlan-mass-create.sh
│   ├── dhcp-mass-config.sh
│   └── test-connectivity.sh
└── docs/
    └── troubleshooting.md
```
---

## Best Practices

1. **Always backup configurations** before making changes
2. **Test in stages** - verify each component works before moving to next
3. **Use version control** for configuration files
4. **Document everything** - especially non-obvious settings
5. **Keep logs** - they're invaluable when things break
6. **Have a rollback plan** - know how to undo changes quickly

---

## Why This Matters

These aren't textbook examplesthey're real problems I solved
