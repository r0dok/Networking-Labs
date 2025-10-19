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

Network Diagram

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

Troubleshooting
No inter-VLAN connectivity

    Check IP forwarding: cat /proc/sys/net/ipv4/ip_forward
    Verify trunk port on switch: show interfaces trunk
    Check default gateways on clients

DHCP not working

    Verify DHCP pools on Cisco switch
    Check excluded address ranges
    Verify gateway addresses match VLAN interfaces

Pi not reachable

    Check static IP configuration
    Verify physical connection to trunk port
    Check switch trunk configuration


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
