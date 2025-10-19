# Windows Server DHCP Configuration

# Scope for Network A (VLAN 10)
Scope Name: Network-A
IP Range: 10.10.10.10 - 10.10.10.50
Subnet Mask: 255.255.255.0
Default Gateway: 10.10.10.254
DNS Server: 10.10.10.4
Lease Duration: 8 hours

Exclusions:
10.10.10.1 - 10.10.10.9 (reserved for infrastructure)

# Scope for Network B (VLAN 20) - via DHCP Relay
Scope Name: Network-B
IP Range: 10.20.20.10 - 10.20.20.50
Subnet Mask: 255.255.255.0
Default Gateway: 10.20.20.254 (pfSense on Network B side)
DNS Server: 10.10.10.4
Lease Duration: 8 hours

Exclusions:
10.20.20.1 - 10.20.20.9 (reserved for infrastructure)

# DHCP Relay Agent Configuration
Relay Agent IP: 10.10.10.4
Listening Interface: All interfaces
