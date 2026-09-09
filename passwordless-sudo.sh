#!/bin/bash

cat > /etc/sudoers.d/luke << 'EOF'
luke ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/luke
chown root:root /etc/sudoers.d/luke