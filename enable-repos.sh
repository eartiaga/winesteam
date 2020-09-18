#!/bin/sh

set -e
set -x

# Enable contrib and non-free packages
echo "deb http://deb.debian.org/debian sid contrib non-free" \
    >> /etc/apt/sources.list
apt-get update -qy

# Enable i386 architecture
dpkg --add-architecture i386
apt-get clean
rm -rf //var/lib/apt/lists/*
apt-get update -qy

# Install basic mulitarch support
# Note: install separately to avoid cross-package conflicts
apt-get update -qy && apt-get install -qy \
    libc6 \
    libgcc-s1

apt-get update -qy && apt-get install -qy \
    libgcc-s1:i386

apt-get update -qy && apt-get install -qy \
    gcc-multilib \
    libc6-i386 \
    libc6:i386

