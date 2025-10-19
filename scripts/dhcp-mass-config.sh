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
