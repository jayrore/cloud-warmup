#!/bin/bash

# Configure SSH client
cat <<"EOF" > /home/ubuntu/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
chmod 600 /home/ubuntu/.ssh/config
chown ubuntu:ubuntu /home/ubuntu/.ssh/config

exit 0