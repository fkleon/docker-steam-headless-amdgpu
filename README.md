> # FORK NOTICE
> This fork supports AMDGPU only, tested on
>
> **AMD Ryzen 7 5825U with Radeon Vega 8 (Renoir/Barcelo)** (gfx90c)
> 
> If you are using different hardware, you should stick with [the original project](https://github.com/Steam-Headless/docker-steam-headless). This fork breaks non-amd gpu support and might break features I don't use.
>
> It is expected that you have [setup a virtual display](https://wiki.archlinux.org/title/AMDGPU#Virtual_display_on_headless_setups), for example by editing `/etc/default/grub` to include `amdgpu.virtual_display=0000:c6:00.0,1` in `GRUB_CMDLINE_LINUX_DEFAULT` (after replacing the PCI address with your own). Otherwise, you will get a black screen.
>
> Once sunshine is up and running, you might want to go to its settings and force it to use the VA-API encoder. Otherwise, the stream will be so laggy it's unplayable.
> 
> <details>
> <summary>Here is my docker-compose for reference (running on TrueNAS 25.04)</summary>
>
> ```yaml
> services:
>   steam-headless:
>     image: fkleon/docker-steam-headless-amdgpu:latest
>     restart: unless-stopped
>     shm_size: 2G
>     ipc: host
>     ulimits:
>       nofile:
>         soft: 1024
>         hard: 524288
>     cap_add:
>       - AUDIT_WRITE
>       - CHOWN
>       - DAC_OVERRIDE
>       - FOWNER
>       - FSETID
>       - KILL
>       - MKNOD
>       - NET_ADMIN
>       - SETGID
>       - SETUID
>       - SYS_ADMIN
>       - SYS_NICE
>       - SYS_RESOURCE
>     security_opt:
>       - seccomp:unconfined
>       - apparmor:unconfined
>     # This is required (see https://github.com/Steam-Headless/docker-steam-headless/issues/157)
>     network_mode: host
> 
>     environment:
>       # System
>       - TZ=Pacific/Auckland
>       - USER_LOCALES=en_US.UTF-8 UTF-8
>       - SHM_SIZE=2G
>       # User
>       - PUID=568
>       - PGID=568
>       - UMASK=000
>       - USER_PASSWORD={{ steam_user_password }}
>       # Mode
>       - MODE=primary
>       # Web UI
>       - WEB_UI_MODE=vnc
>       - PORT_NOVNC_WEB=31313
>       # Steam
>       - ENABLE_STEAM=true
>       - STEAM_ARGS=-silent
>       # Sunshine
>       - ENABLE_SUNSHINE=false
>       - SUNSHINE_USER=sunshine
>       - SUNSHINE_PASS={{ sunshine_password }}
>       # Xorg
>       - ENABLE_EVDEV_INPUTS=true
>       - FORCE_X11_DUMMY_CONFIG=true
> 
>     devices:
>       - /dev/fuse
>       - /dev/uinput
>       # Add AMD/Intel HW accelerated video encoding/decoding devices
>       # Obtained from `lspci | grep -iE "vga|3d|display"` and `ls /dev/dri/`
>       - /dev/dri/card0
>       - /dev/dri/renderD128
>       # - /dev/kfd  # Kernel Fusion Driver for AMD GPUs (for compute tasks like OpenCL, ROCm, etc.)
>       # - /dev/snd  # Sound card devices
>     
>     device_cgroup_rules:
>       - 'c 13:* rmw' # Ensure container access to devices 13:*
> 
>     extra_hosts:
>       - steam-headless:127.0.0.1
>     hostname: steam-headless
>     volumes:
>       # The location of your home directory.
>       - /data/steam/home/:/home/default/:rw
>     x-notes: |
>       # Steam Headless AMDGPU
>
>       * https://github.com/fkleon/docker-steam-headless-amdgpu
>
>     x-portals:
>       - host: {{ truenas_hostname }}
>         name: Web VNC
>         path: /
>         port: 31313
>         scheme: http
> ```
> </details>

# Headless Steam Service

![](./images/banner.jpg)

Remote Game Streaming Server.

Play your games either in the browser with audio or via Steam Link or Moonlight. Play from another Steam Client with Steam Remote Play.

Easily deploy a Steam Docker instance in seconds.

## Features:
- Steam Client configured for running on Linux with Proton
- Moonlight compatible server for easy remote desktop streaming
- Easy installation of EmeDeck, Heroic and Lutris via Flatpak
- Full video/audio noVNC web access to a Xfce4 Desktop
- AMD and Intel GPU support
- Full controller support
- Support for Flatpak and Appimage installation
- Root access
- Based on Debian Trixie

---
## Notes:

### ADDITIONAL SOFTWARE:
If you wish to install additional applications, you can generate a script inside the `~/init.d` directory ending with ".sh".
This will be executed on the container startup.

Also, you can install applications using the WebUI under **Applications > System > Software**. There you can install other game launchers like Lutris, Heroic or EmuDeck.

### STORAGE PATHS:
Everything that you wish to save in this container should be stored in the home directory or a docker container mount that you have specified. 
All files that are store outside your home directory are not persistent and will be wiped if there is an update of the container or you change something in the template.

### GAMES LIBRARY:
It is recommended that you mount your games library to `/mnt/games` and configure Steam to add that path.

### AUTO START APPLICATIONS:
In this container, Steam is configured to automatically start. If you wish to add additional services to automatically start, 
add them under **Applications > Settings > Session and Startup** in the WebUI.

### NETWORK MODE:
If you want to use the container as a Steam Remote Play (previously "In Home Streaming") host device you should create a custom network and assign this container it's own IP, if you don't do this the traffic will be routed through the internet since Steam thinks you are on a different network.

### USING HOST X SERVER:
If your host is already running X, you can just use that. To do this, be sure to configure:
  - DISPLAY=:0    
    **(Variable)** - *Configures the sceen to use the primary display. Set this to whatever your host is using*
  - MODE=secondary    
    **(Variable)** - *Configures the container to not start an X server of its own*
  - HOST_DBUS=true    
    **(Variable)** - *Optional - Configures the container to use the host dbus process*
  - /run/dbus:/run/dbus:ro    
    **(Mount)**  - *Optional - Configures the container to use the host dbus process*


---
## Installation:
- [Docker Compose](./docs/docker-compose.md)
- [Unraid](./docs/unraid.md)
- [Ubuntu Server](./docs/ubuntu-server.md)


---
## Running locally:

For a development environment, I have created a script in the devops directory.


---
## TODO:
- Remove SSH
- Require user to enter password for sudo
- Document how to run this container:
    - Other server OS
    - TrueNAS Scale 
