bash
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
