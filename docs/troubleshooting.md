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
- DHCP relay enabled on pfSense for Network B interface
- Firewall rules allow UDP 67/68
- Windows Server DHCP has scope for 10.20.20.0/24
- Default gateway in DHCP scope points to correct pfSense interface

**Solution:**
```powershell
# Windows Server - verify DHCP scope
Get-DhcpServerv4Scope
```

On pfSense:
- Services > DHCP Relay > Enable
- Destination servers: 10.10.10.4

#### Problem: DNS resolution fails

**Symptoms:** Can ping IPs but not hostnames

**Check:**
- DNS forwarding enabled on pfSense
- Clients have correct DNS server (10.10.10.4)
- Windows Server DNS service running
- Firewall allows UDP/TCP 53

**Solution:**
```bash
# Test DNS from client
nslookup google.com 10.10.10.4

# Windows Server - check DNS service
Get-Service DNS
```

### Lab 2: Raspberry Pi VLAN Router

#### Problem: Inter-VLAN routing not working

**Symptoms:** Devices in different VLANs cannot communicate

**Check:**
- IP forwarding enabled on Pi: cat /proc/sys/net/ipv4/ip_forward (should be 1)
- Trunk port configured correctly on switch
- VLAN interfaces up on switch
- Default gateways correct on clients

**Solution:**
```bash
# Raspberry Pi - enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo nano /etc/sysctl.conf
# Add: net.ipv4.ip_forward=1
```

Cisco Switch checks:
```text
# Cisco Switch - verify trunk
show interfaces fastEthernet 0/2 trunk
show vlan brief

# Check routing
ip route
```

#### Problem: Raspberry Pi unreachable

**Symptoms:** Cannot SSH to Pi or ping it

**Check:**
- Physical connection to trunk port (F0/2)
- Static IP configured correctly (192.168.1.11)
- Trunk port allows VLAN 10 (native or tagged)
- Switch VLAN 10 interface has IP

**Solution:**
```bash
# Raspberry Pi - check network config
ip addr show eth0
ip route
```

On the Cisco Switch:
```text
# Cisco Switch - verify interface
show interface fastEthernet 0/2
show running-config interface fastEthernet 0/2
```

#### Problem: DHCP pools exhausted

**Symptoms:** Some clients get IP, others don't

**Check:**
- DHCP pool size vs. number of clients
- Excluded address ranges
- Lease time too long
- Old leases not expiring

**Solution:**
```text
! Expand DHCP pool range
ip dhcp pool pool10
 network 192.168.1.0 255.255.255.0
 ! Increase range
 no ip dhcp excluded-address 192.168.1.1 192.168.1.15
 ip dhcp excluded-address 192.168.1.1 192.168.1.10

! Clear old bindings
clear ip dhcp binding *
```

### Lab 3: Mass VLAN Automation

#### Problem: Script fails during execution

**Symptoms:** Script stops partway through, incomplete configuration

**Check:**
- SSH connectivity to switch
- Expect package installed
- Switch credentials correct
- Timeout values sufficient for 200 VLANs

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
- VLAN interfaces are up: show ip interface brief | include up
- IP routing enabled: show ip route
- Trunk port allows all VLANs
- No IP conflicts

**Solution:**
```text
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
- Configuration syntax errors in dnsmasq.conf
- Port 67 already in use
- Network interfaces don't exist yet
- Permissions on config file

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
- Wait for VLANs to fully initialize
- Routing convergence completed
- Switch CPU not overloaded
- Network congestion

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

## General Troubleshooting Commands

### Cisco IOS
```text
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

## Best Practices

- Always backup configurations before making changes
- Test in stages - verify each component works before moving to next
- Use version control for configuration files
- Document everything - especially non-obvious settings
- Keep logs - they're invaluable when things break
- Have a rollback plan - know how to undo changes quickly

## Getting Help

When asking for help, include:

- Exact error messages
- Relevant configuration snippets
- Output of diagnostic commands
- What you've already tried
- Network diagram of your setup

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
