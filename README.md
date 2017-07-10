# OpenXcom AppImage package

## Introduction
This repository automates building AppImage packages of OpenXcom game. 

Packages for x86-64 (64-bit Intel/AMD) and x86 (32-bit Intel/AMD) architectures are generated daily by Travis CI build system and can be downloaded from https://knapsu.eu/openxcom/.

## OpenXcom
OpenXcom is an open-source clone of the popular UFO: Enemy Unknown (X-COM: UFO Defense in USA) turn-based strategy game by MicroProse.

For more information about OpenXcom please visit https://openxcom.org/ site.

## AppImage
AppImages is a universal Linux package that can be used in any modern Linux distribution.

For more information about AppImage package please visit http://appimage.org/ site.

## Docker

Directory `docker` contains files used to create a Docker image of a fully functional build environment. This build environment image is used by Travis CI to create and publish the binaries. Using Docker also makes it easy to reproduce builds on other systems.

### Docker images
- [knapsu/openxcom-build](https://hub.docker.com/r/knapsu/openxcom-build/)
- [knapsu/openxcom-build-x86](https://hub.docker.com/r/knapsu/openxcom-build-x86/)
