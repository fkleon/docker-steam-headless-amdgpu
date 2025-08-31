# Unraid

Follow these instructions to install Steam Headless on Unraid

## CONTAINER TEMPLATE:

1. Navigate to "**APPS**" tab.
2. Search for "*steam-headless*"
3. Select either **Install** or **Actions > Install** from the search result.
![](./images/install-steam-headless-unraid-ca.png)
4. Configure the template as required.


## GPU CONFIGURATION:

This container can use your dedicated GPU. 
In order for it to do this you need to have the Radeon-Top plugin installed.

### AMD

1. Install the [Radeon-Top Plugin](https://forums.unraid.net/topic/92865-support-ich777-amd-vendor-reset-coraltpu-hpsahba/) by [ich777](https://forums.unraid.net/profile/72388-ich777/).
![](./images/unraid-amd-plugin.png)
2. Profit


## ADDING CONTROLLER SUPPORT:

Unraid's Linux kernel by default does not have the modules required to support controller input. Steam requires these modules to be able to create the virtual "Steam Input Gamepad Emulation" device that it can then map buttons to.

[ich777](https://forums.unraid.net/profile/72388-ich777/) has kindly offered to build and maintain the required modules for the Unraid kernel as he already has a CI/CD pipeline in place and a small number of other kernel modules that he is maintaining for other projects. So a big thanks to him for that!

> __Note__
>
> This may no longer be required with Unraid v6.11 release (TBD). The required uinput module should be added to the kernel for that release.

1. Install the **uinput** plugin from the **Apps** tab.
![](./images/unraid-steam-headless-install-uinput-plugin.png)
2. The container will not be able to receive kernel events from the host unless the **Network Type:** is set to "*host*". Ensure that you container is configured this way.
![](./images/unraid-steam-headless-configure-network-as-host.png)

    > __Warning__
    >
    > Be aware that, by default, this container requires at least 8083 available for the WebUI to work. It will also require any ports that Steam requires for Steam Remote Play.

    You can override the default ports used by the container with these variables:
    - PORT_NOVNC_WEB (Default: 8083)
    - WEB_UI_MODE (Default: 'vnc' - Set to 'none' to disable the WebUI)

3. No server restart is required, however. Ensure that the **steam-headless** Docker container is recreated after installing the **uinput** plugin for it to be able to detect the newly added module.
