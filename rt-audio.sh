#!/bin/bash

mkdir -p /etc/security/limits.d

cat > /etc/security/limits.d/95-pipewire.conf << 'EOF'
@audio    -    rtprio     95
@audio    -    nice       -19
@audio    -    memlock    unlimited
EOF

usermod -aG audio luke
