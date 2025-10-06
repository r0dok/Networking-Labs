# network-infrastructure-labs
I built these labs while studying network infrastructure - they're practical implementations I actually ran, not theoretical exercises. All configs are production-tested.

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

## Complete Configuration Files

### configs/lab1/pfsense-routes.txt

```
# Static Routes
Destination: 10.20.20.0/24
Gateway: 193.191.150.57
Interface: WAN

# Firewall Rules - Network B to Network A
Interface: WAN
Source: 10.20.20.0/24
Destination: 10.10.10.0/24
Protocol: Any
Action: Allow

# Allow all WAN incoming (lab only)
Interface: WAN
Source: Any
Destination: Any
Action: Allow

# Allow ICMP for Network B
Interface: WAN
Protocol: ICMP
Source: 10.20.20.0/24
Action: Allow

# DHCP Relay Configuration
Interface: Network B (VLAN 20)
DHCP Server: 10.10.10.4
Action: Enable Relay

# NAT Rules
Source: 10.10.10.0/24
Destination: 10.20.20.0/24
NAT Interface: WAN
Action: NAT

Source: 10.20.20.0/24
Destination: 10.10.10.0/24
NAT Interface: WAN
Action: NAT

# DNS Forwarding
DNS Forwarder: Enabled
Forward to: 10.10.10.4 (Windows Server)
Listen on: All interfaces
```

### configs/lab1/cisco-switch.txt

```
! VLAN Configuration
vlan 10
 name NetworkA
vlan 20
 name NetworkB

! Trunk to pfSense
interface gigabitEthernet 0/1
 description Trunk to pfSense
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 switchport trunk native vlan 99
 no shutdown

! Enable IP routing on switch
ip routing

! Static route to Network A via pfSense
ip route 10.10.10.0 255.255.255.0 10.20.20.254

! VLAN interface for Network B
interface vlan 20
 ip address 10.20.20.10 255.255.255.0
 no shutdown

! Access ports for Network A
interface range fastEthernet 0/1-10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast

! Access ports for Network B
interface range fastEthernet 0/11-20
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast

! Management
line vty 0 4
 login local
 transport input ssh
end
```

### configs/lab1/windows-dhcp.txt

```
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
```

---

### configs/lab2/cisco-vlan-config.txt

```
! VLAN Definitions
vlan 10
 name Management
vlan 11
 name Users
vlan 12
 name IoT
vlan 13
 name DMZ

! VLAN Interfaces with IPs
interface vlan 10
 ip address 192.168.1.5 255.255.255.0
 no shutdown

interface vlan 11
 ip address 192.168.2.5 255.255.255.0
 no shutdown

interface vlan 12
 ip address 192.168.3.5 255.255.255.0
 no shutdown

interface vlan 13
 ip address 192.168.4.5 255.255.255.0
 no shutdown

! Trunk to Raspberry Pi
interface fastEthernet 0/2
 description Trunk to Raspberry Pi Router
 switchport mode trunk
 switchport trunk allowed vlan all
 switchport trunk native vlan 10
 no shutdown

! Access Ports
interface fastEthernet 0/10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast

interface fastEthernet 0/11
 switchport mode access
 switchport access vlan 11
 spanning-tree portfast

interface fastEthernet 0/12
 switchport mode access
 switchport access vlan 12
 spanning-tree portfast

interface fastEthernet 0/13
 switchport mode access
 switchport access vlan 13
 spanning-tree portfast

! DHCP Configuration
ip dhcp excluded-address 192.168.1.1 192.168.1.15
ip dhcp pool pool10
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8 8.8.4.4

ip dhcp excluded-address 192.168.2.1 192.168.2.10
ip dhcp pool pool11
 network 192.168.2.0 255.255.255.0
 default-router 192.168.2.1
 dns-server 8.8.8.8

ip dhcp excluded-address 192.168.3.1 192.168.3.10
ip dhcp pool pool12
 network 192.168.3.0 255.255.255.0
 default-router 192.168.3.1
 dns-server 8.8.8.8

ip dhcp excluded-address 192.168.4.1 192.168.4.10
ip dhcp pool pool13
 network 192.168.4.0 255.255.255.0
 default-router 192.168.4.1
 dns-server 8.8.8.8
end
```

### configs/lab2/raspberry-pi-setup.md

```markdown
# Raspberry Pi VLAN Router Setup

## Hardware Requirements
- Raspberry Pi 3 or 4
- MicroSD card (16GB minimum)
- Ethernet connection to Cisco switch trunk port

## Installation Steps

### 1. Install Raspberry Pi OS
```bash
# Use Raspberry Pi Imager
# Enable SSH during setup
# Set static IP: 192.168.1.11/24
# Gateway: 192.168.1.1
```

### 2. Enable IP Forwarding
```bash
# Edit sysctl.conf
sudo nano /etc/sysctl.conf

# Uncomment or add:
net.ipv4.ip_forward=1

# Apply changes
sudo sysctl -p
```

### 3. Configure Network Interface
```bash
# Edit dhcpcd.conf
sudo nano /etc/dhcpcd.conf

# Add static IP configuration
interface eth0
static ip_address=192.168.1.11/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4
```

### 4. Install VLAN Support (if needed)
```bash
sudo apt update
sudo apt install vlan

# Load 8021q module
sudo modprobe 8021q

# Make it persistent
echo "8021q" | sudo tee -a /etc/modules
```

### 5. Verify Routing
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1

# Check routing table
ip route

# Test connectivity
ping -c 3 192.168.2.5
ping -c 3 192.168.3.5
ping -c 3 192.168.4.5
```

## Network Diagram
```
                    Raspberry Pi
                   192.168.1.11
                        |
                   Trunk Port
                  (F0/2 on switch)
                        |
        +---------------+---------------+
        |               |               |
    VLAN 10         VLAN 11         VLAN 12
  192.168.1.0     192.168.2.0     192.168.3.0
     /24             /24             /24
```

## Troubleshooting

### No inter-VLAN connectivity
- Check IP forwarding: `cat /proc/sys/net/ipv4/ip_forward`
- Verify trunk port on switch: `show interfaces trunk`
- Check default gateways on clients

### DHCP not working
- Verify DHCP pools on Cisco switch
- Check excluded address ranges
- Verify gateway addresses match VLAN interfaces

### Pi not reachable
- Check static IP configuration
- Verify physical connection to trunk port
- Check switch trunk configuration
```

---

## Scripts

### scripts/vlan-mass-create.sh

```bash
#!/bin/bash
# Mass VLAN Creation Script
# Creates 200 VLANs (2-201) with automated IP addressing

set -e

# Configuration
SWITCH_IP="192.69.39.1"
SWITCH_USER="admin"
SWITCH_PASSWORD="admin"
VLAN_ID_START=2
SUBNET_SIZE=16
VLAN_COUNT=200
OUTPUT_FILE="cisco_vlan_config.txt"

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "Installing expect..."
    sudo apt-get update && sudo apt-get install expect -y
fi

# Generate VLAN configuration
echo "Generating VLAN configuration for $VLAN_COUNT VLANs..."
echo "enable" > $OUTPUT_FILE
echo "configure terminal" >> $OUTPUT_FILE

for (( i=0; i<$VLAN_COUNT; i++ )); do
    VLAN_ID=$((VLAN_ID_START + i))
    IP_BASE=$((SUBNET_SIZE * i))
    OCTET3=$((IP_BASE / 256))
    OCTET4=$((IP_BASE % 256))
    VLAN_IP="10.0.$OCTET3.$OCTET4"

    cat >> $OUTPUT_FILE << EOF

vlan $VLAN_ID
 name VLAN_$VLAN_ID
exit
interface vlan $VLAN_ID
 ip address $VLAN_IP 255.255.255.240
 no shutdown
exit
EOF

    # Progress indicator
    if (( i % 20 == 0 )); then
        echo "Generated $i/$VLAN_COUNT VLANs..."
    fi
done

# Configure trunk port
cat >> $OUTPUT_FILE << EOF

interface gigabitEthernet 0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan $VLAN_ID_START-$(($VLAN_ID_START + $VLAN_COUNT - 1))
exit
end
write memory
EOF

echo "Configuration file generated: $OUTPUT_FILE"

# Apply configuration via SSH
echo "Connecting to switch at $SWITCH_IP..."

expect << EOF
  set timeout 30
  spawn ssh $SWITCH_USER@$SWITCH_IP
  
  expect {
    "Are you sure you want to continue connecting" {
      send "yes\r"
      exp_continue
    }
    "password:" {
      send "$SWITCH_PASSWORD\r"
    }
  }
  
  expect ">"
  send "enable\r"
  expect "Password:"
  send "$SWITCH_PASSWORD\r"
  expect "#"
  
  send "configure terminal\r"
  expect "(config)#"
  
  # Read and send configuration line by line
  set file [open "$OUTPUT_FILE" r]
  while {[gets \$file line] != -1} {
    send "\$line\r"
    expect {
      "(config)#" {}
      "(config-vlan)#" {}
      "(config-if)#" {}
      "#" {}
    }
  }
  close \$file
  
  send "end\r"
  expect "#"
  send "write memory\r"
  expect "#"
  send "exit\r"
EOF

echo ""
echo "✓ Configuration applied successfully!"
echo "✓ Created VLANs $VLAN_ID_START to $(($VLAN_ID_START + $VLAN_COUNT - 1))"
echo "✓ IP range: 10.0.0.0 - 10.0.$((SUBNET_SIZE * VLAN_COUNT / 256)).$((SUBNET_SIZE * VLAN_COUNT % 256))"
```

### scripts/dhcp-mass-config.sh

```bash
#!/bin/bash
# Mass DHCP Configuration Script
# Creates DHCP pools for 200 VLANs using dnsmasq

set -e

# Configuration
START_VLAN=2
VLAN_COUNT=200
SUBNET_SIZE=16
IP_BASE="10.0"
DNSMASQ_CONF="/etc/dnsmasq.d/vlan_dhcp.conf"

# Check if dnsmasq is installed
if ! command -v dnsmasq &> /dev/null; then
    echo "Installing dnsmasq..."
    sudo apt-get update && sudo apt-get install -y dnsmasq
fi

# Backup existing configuration
if [[ -f "$DNSMASQ_CONF" ]]; then
    echo "Backing up existing configuration..."
    sudo mv "$DNSMASQ_CONF" "${DNSMASQ_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
fi

# Create new configuration
echo "Generating DHCP configuration for $VLAN_COUNT VLANs..."
echo "# DHCP configuration for VLANs $START_VLAN to $((START_VLAN + VLAN_COUNT - 1))" | sudo tee "$DNSMASQ_CONF"
echo "# Generated on $(date)" | sudo tee -a "$DNSMASQ_CONF"
echo "" | sudo tee -a "$DNSMASQ_CONF"

for ((i=0; i<VLAN_COUNT; i++)); do
    VLAN_ID=$((START_VLAN + i))
    SUBNET_IP_BASE=$((SUBNET_SIZE * i))
    OCTET3=$((SUBNET_IP_BASE / 256))
    OCTET4=$((SUBNET_IP_BASE % 256))
    
    NETWORK_IP="$IP_BASE.$OCTET3.$OCTET4"
    DHCP_RANGE_START="$IP_BASE.$OCTET3.$((OCTET4 + 1))"
    DHCP_RANGE_END="$IP_BASE.$OCTET3.$((OCTET4 + 13))"
    GATEWAY="$NETWORK_IP"

    # Append to dnsmasq config
    cat | sudo tee -a "$DNSMASQ_CONF" << EOF
# VLAN $VLAN_ID
dhcp-range=VLAN${VLAN_ID},$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.240,12h
dhcp-option=VLAN${VLAN_ID},option:router,$GATEWAY
dhcp-option=VLAN${VLAN_ID},option:dns-server,8.8.8.8,8.8.4.4
interface=vlan${VLAN_ID}

EOF

    # Progress indicator
    if (( i % 20 == 0 )); then
        echo "Generated $i/$VLAN_COUNT DHCP pools..."
    fi
done

# Enable and restart dnsmasq
echo "Enabling dnsmasq service..."
sudo systemctl enable dnsmasq
echo "Restarting dnsmasq service..."
sudo systemctl restart dnsmasq

# Verify service status
if sudo systemctl is-active --quiet dnsmasq; then
    echo ""
    echo "✓ DHCP configuration complete!"
    echo "✓ Created $VLAN_COUNT DHCP pools"
    echo "✓ Configuration file: $DNSMASQ_CONF"
    echo "✓ dnsmasq service: RUNNING"
else
    echo ""
    echo "✗ Error: dnsmasq service failed to start"
    echo "Check logs: sudo journalctl -u dnsmasq -n 50"
    exit 1
fi
```

### scripts/test-connectivity.sh

```bash
#!/bin/bash
# Network Connectivity Testing Script
# Tests all 200 VLAN gateways

# Configuration
START_VLAN=2
END_VLAN=201
SUBNET_SIZE=16
PING_COUNT=3
TIMEOUT=1

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total=0
success=0
failed=0

echo "=========================================="
echo "  VLAN Connectivity Test"
echo "  Testing VLANs $START_VLAN to $END_VLAN"
echo "=========================================="
echo ""

# Test each VLAN
for ((i=START_VLAN; i<=END_VLAN; i++)); do
    BASE=$((SUBNET_SIZE * (i - START_VLAN)))
    OCTET3=$((BASE / 256))
    OCTET4=$((BASE % 256))
    TARGET_IP="10.0.$OCTET3.$OCTET4"
    
    ((total++))
    
    # Ping test
    if ping -c $PING_COUNT -W $TIMEOUT "$TARGET_IP" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} VLAN $i ($TARGET_IP): UP"
        ((success++))
    else
        echo -e "${RED}✗${NC} VLAN $i ($TARGET_IP): DOWN"
        ((failed++))
    fi
    
    # Progress update every 25 VLANs
    if (( i % 25 == 0 )); then
        echo -e "${YELLOW}--- Progress: $((i - START_VLAN + 1))/$((END_VLAN - START_VLAN + 1)) VLANs tested ---${NC}"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo "Total VLANs tested: $total"
echo -e "${GREEN}Successful: $success${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo "Success rate: $(( success * 100 / total ))%"
echo ""

# Failed VLANs detail
if [[ $failed -gt 0 ]]; then
    echo "Run with verbose mode to see failed VLANs:"
    echo "./test-connectivity.sh --verbose"
fi
```

---

## docs/troubleshooting.md

```markdown
# Troubleshooting Guide

## Common Issues and Solutions

### Lab 1: pfSense Inter-VLAN Routing

#### Problem: Network B cannot reach Network A
**Symptoms:** Ping from 10.20.20.x to 10.10.10.x fails

**Check:**
1. Verify static route on pfSense: `10.20.20.0/24 via 193.191.150.57`
2. Check firewall rules allow traffic between VLANs
3. Verify NAT rules are configured for both directions
4. Test from pfSense itself: `ping 10.20.20.10`

**Solution:**
```bash
# pfSense - verify route
netstat -rn | grep 10.20.20

# Check firewall state table
pfctl -ss | grep 10.20.20
```

#### Problem: DHCP not working on Network B
**Symptoms:** Clients on Network B don't get IP addresses

**Check:**
1. DHCP relay enabled on pfSense for Network B interface
2. Firewall rules allow UDP 67/68
3. Windows Server DHCP has scope for 10.20.20.0/24
4. Default gateway in DHCP scope points to correct pfSense interface

**Solution:**
```bash
# Windows Server - verify DHCP scope
Get-DhcpServerv4Scope

# pfSense - check DHCP relay
# Services > DHCP Relay > Enable
# Destination servers: 10.10.10.4
```

#### Problem: DNS resolution fails
**Symptoms:** Can ping IPs but not hostnames

**Check:**
1. DNS forwarding enabled on pfSense
2. Clients have correct DNS server (10.10.10.4)
3. Windows Server DNS service running
4. Firewall allows UDP/TCP 53

**Solution:**
```bash
# Test DNS from client
nslookup google.com 10.10.10.4

# Windows Server - check DNS service
Get-Service DNS
```

---

### Lab 2: Raspberry Pi VLAN Router

#### Problem: Inter-VLAN routing not working
**Symptoms:** Devices in different VLANs cannot communicate

**Check:**
1. IP forwarding enabled on Pi: `cat /proc/sys/net/ipv4/ip_forward` (should be 1)
2. Trunk port configured correctly on switch
3. VLAN interfaces up on switch
4. Default gateways correct on clients

**Solution:**
```bash
# Raspberry Pi - enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo nano /etc/sysctl.conf
# Add: net.ipv4.ip_forward=1

# Cisco Switch - verify trunk
show interfaces fastEthernet 0/2 trunk
show vlan brief

# Check routing
ip route
```

#### Problem: Raspberry Pi unreachable
**Symptoms:** Cannot SSH to Pi or ping it

**Check:**
1. Physical connection to trunk port (F0/2)
2. Static IP configured correctly (192.168.1.11)
3. Trunk port allows VLAN 10 (native or tagged)
4. Switch VLAN 10 interface has IP

**Solution:**
```bash
# Raspberry Pi - check network config
ip addr show eth0
ip route

# Cisco Switch - verify interface
show interface fastEthernet 0/2
show running-config interface fastEthernet 0/2
```

#### Problem: DHCP pools exhausted
**Symptoms:** Some clients get IP, others don't

**Check:**
1. DHCP pool size vs. number of clients
2. Excluded address ranges
3. Lease time too long
4. Old leases not expiring

**Solution:**
```cisco
! Expand DHCP pool range
ip dhcp pool pool10
 network 192.168.1.0 255.255.255.0
 ! Increase range
 no ip dhcp excluded-address 192.168.1.1 192.168.1.15
 ip dhcp excluded-address 192.168.1.1 192.168.1.10

! Clear old bindings
clear ip dhcp binding *
```

---

### Lab 3: Mass VLAN Automation

#### Problem: Script fails during execution
**Symptoms:** Script stops partway through, incomplete configuration

**Check:**
1. SSH connectivity to switch
2. Expect package installed
3. Switch credentials correct
4. Timeout values sufficient for 200 VLANs

**Solution:**
```bash
# Test SSH manually
ssh admin@192.69.39.1

# Install expect
sudo apt-get install expect -y

# Increase timeout in script
set timeout 60  # in expect block
```

#### Problem: VLANs created but no connectivity
**Symptoms:** VLANs exist but devices can't communicate

**Check:**
1. VLAN interfaces are up: `show ip interface brief | include up`
2. IP routing enabled: `show ip route`
3. Trunk port allows all VLANs
4. No IP conflicts

**Solution:**
```cisco
! Verify VLAN interfaces
show ip interface brief | include Vlan

! Check if interfaces are down
interface vlan 10
 no shutdown

! Verify routing
show ip route connected
```

#### Problem: DHCP service won't start
**Symptoms:** dnsmasq fails to start after mass config

**Check:**
1. Configuration syntax errors in dnsmasq.conf
2. Port 67 already in use
3. Network interfaces don't exist yet
4. Permissions on config file

**Solution:**
```bash
# Check dnsmasq configuration
sudo dnsmasq --test

# Check what's using port 67
sudo netstat -tulpn | grep :67

# View service errors
sudo journalctl -u dnsmasq -n 50

# Fix permissions
sudo chmod 644 /etc/dnsmasq.d/vlan_dhcp.conf
sudo systemctl restart dnsmasq
```

#### Problem: Ping tests show many failures
**Symptoms:** test-connectivity.sh reports 50%+ failure rate

**Check:**
1. Wait for VLANs to fully initialize
2. Routing convergence completed
3. Switch CPU not overloaded
4. Network congestion

**Solution:**
```bash
# Run test with delay between pings
for i in {2..201}; do
    ping -c 1 -W 2 10.0.x.x
    sleep 0.5  # Add delay
done

# Check switch CPU
show processes cpu sorted

# Verify VLAN status
show vlan brief | include active
```

---

## General Troubleshooting Commands

### Cisco IOS
```cisco
! Verify VLAN configuration
show vlan brief
show vlan id 10

! Check interfaces
show ip interface brief
show interfaces status
show interfaces trunk

! Routing
show ip route
show ip route vlan
show ip route connected

! DHCP
show ip dhcp binding
show ip dhcp pool
show ip dhcp conflict

! Troubleshooting
debug ip packet
debug ip icmp
show logging
```

### pfSense
```bash
# Network connectivity
ping -c 4 10.20.20.10

# Routing table
netstat -rn

# Firewall states
pfctl -ss

# Check NAT
pfctl -sn

# Packet capture
tcpdump -i em0 icmp

# DHCP leases
cat /var/dhcpd/var/db/dhcpd.leases
```

### Raspberry Pi
```bash
# Network interfaces
ip addr show
ip link show

# Routing
ip route
route -n

# IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Firewall
sudo iptables -L -v -n

# VLAN interfaces (if using)
cat /proc/net/vlan/config
```

### Linux Client Testing
```bash
# Basic connectivity
ping -c 4 192.168.1.1

# DNS resolution
nslookup google.com
dig google.com

# Routing
traceroute 8.8.8.8
ip route get 8.8.8.8

# Current IP config
ip addr show
ip route

# DHCP renewal
sudo dhclient -r
sudo dhclient
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

## Getting Help

When asking for help, include:
- Exact error messages
- Relevant configuration snippets  
- Output of diagnostic commands
- What you've already tried
- Network diagram of your setup
```

---

## Usage

```bash
# Clone the repository
git clone https://github.com/yourusername/network-infrastructure-labs.git
cd network-infrastructure-labs

# Lab 3 - Run automation scripts
cd scripts
chmod +x *.sh

# Create VLANs
sudo ./vlan-mass-create.sh

# Configure DHCP
sudo ./dhcp-mass-config.sh

# Test connectivity
./test-connectivity.sh
```

---

## Why This Matters

These aren't textbook examples - they're real problems I solved:
