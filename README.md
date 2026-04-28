# Argus Yocto Raspberry Pi 3 ROS 2 Proof of Concept

This project documents a Yocto/BitBake proof-of-concept image for a Raspberry Pi 3B running:

- Poky / Yocto Kirkstone
- meta-raspberrypi BSP
- systemd as PID 1
- apt/dpkg runtime package tooling using Yocto-generated `.deb` packages
- onboard Wi-Fi configured with systemd services
- ROS 2 Humble from meta-ros
- ROS 2 C++ demo nodes running on-device

The goal was to explore reproducible embedded Linux image construction for future Argus Cybernetics edge/robotics deployments.

## Usage

Saving a snapshot: 
```
cd ~/yocto-rpi3/poky
source oe-init-build-env ../build-rpi3

~/yocto-rpi3/scripts/snapshot-rpi3-image.sh
```
