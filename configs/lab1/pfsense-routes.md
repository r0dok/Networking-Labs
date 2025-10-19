# pfSense Configuration for Lab 1: Inter-VLAN Routing

## This configuration enables routing between Network A (VLAN 10) and Network B (VLAN 20)


## Static Routes
Destination: 10.20.20.0/24  
Gateway: 193.191.150.57  
Interface: WAN  
Description: Route to Network B via external gateway

## Firewall Rules - Network B to Network A
Interface: WAN  
Source: 10.20.20.0/24  
Destination: 10.10.10.0/24  
Protocol: Any  
Action: Allow  
Description: Allow Network B to access Network A

## Allow all WAN incoming (LAB ONLY - DO NOT USE IN PRODUCTION)

Interface: WAN  
Source: Any  
Destination: Any  
Action: Allow  
Description: TESTING ONLY - Remove in production

## Allow ICMP for Network B

Interface: WAN  
Protocol: ICMP  
Source: 10.20.20.0/24  
Action: Allow  
Description: Enable ping from Network B

## DHCP Relay Configuration

Interface: Network B (VLAN 20)  
DHCP Server: 10.10.10.4  
Action: Enable Relay  
Description: Relay DHCP requests from Network B to Windows Server

## NAT Rules

# NAT for Network A to Network B  
Source: 10.10.10.0/24  
Destination: 10.20.20.0/24  
NAT Interface: WAN  
Action: NAT

# NAT for Network B to Network A  
Source: 10.20.20.0/24  
Destination: 10.10.10.0/24  
NAT Interface: WAN  
Action: NAT

## DNS Forwarding

DNS Forwarder: Enabled  
Forward to: 10.10.10.4 (Windows Server)  
Listen on: All interfaces  
Cache Size: 10000
