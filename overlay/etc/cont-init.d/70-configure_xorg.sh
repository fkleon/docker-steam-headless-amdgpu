
export monitor_connected=$(cat /sys/class/drm/card*/status | awk '/^connected/ { print $1; }' | head -n1)

# Fech current configuration (if modified in UI)
if [ -f "${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml" ]; then
    new_display_sizew=$(cat ${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml | grep Resolution | head -n1 | grep -oP '(?<=value=").*?(?=")' | cut -d'x' -f1)
    new_display_sizeh=$(cat ${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml | grep Resolution | head -n1 | grep -oP '(?<=value=").*?(?=")' | cut -d'x' -f2)
    new_display_refresh=$(cat ${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml | grep RefreshRate | head -n1 | grep -oP '(?<=value=").*?(?=")' | cut -d'x' -f2)
    if [ "${new_display_sizew}x" != "x" ] && [ "${new_display_sizeh}x" != "x" ] && [ "${new_display_refresh}x" != "x" ]; then
        export DISPLAY_SIZEW="${new_display_sizew}"
        export DISPLAY_SIZEH="${new_display_sizeh}"
        # Round refresh rate to closest multiple of 60
        export DISPLAY_REFRESH="$(echo ${new_display_refresh} | awk '{rounded = int(($1 + 30) / 60) * 60; if (rounded < 30) rounded += 60; print rounded}')"
    fi
fi

# Allow anybody for running x server
function configure_x_server {
    # Configure x to be run by anyone
    if [[ ! -f /etc/X11/Xwrapper.config ]]; then
        print_step_header "Create Xwrapper.config"
        echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config
        echo 'needs_root_rights=yes' >> /etc/X11/Xwrapper.config
    elif grep -Fxq "allowed_users=console" /etc/X11/Xwrapper.config; then
        print_step_header "Configure Xwrapper.config"
        sed -i "s/allowed_users=console/allowed_users=anybody/" /etc/X11/Xwrapper.config
        echo 'needs_root_rights=yes' >> /etc/X11/Xwrapper.config
    fi

    # Remove previous Xorg config
    rm -f /etc/X11/xorg.conf

    # Ensure the X socket path exists
    mkdir -p ${XORG_SOCKET_DIR:?}

    # Clear out old lock files
    display_file=${XORG_SOCKET_DIR}/X${DISPLAY#:}
    if [ -S ${display_file} ]; then
        print_step_header "Removing ${display_file} before starting"
        rm -f /tmp/.X${DISPLAY#:}-lock
        rm ${display_file}
    fi

    # Ensure X-windows session path is owned by root 
    mkdir -p /tmp/.ICE-unix
    chown root:root /tmp/.ICE-unix/
    chmod 1777 /tmp/.ICE-unix/

    # Check if this container is being run as a secondary instance
    if ([ "${MODE}" = "p" ] || [ "${MODE}" = "primary" ]); then
        print_step_header "Configure container as primary the X server"
        # Enable supervisord script
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/xorg.ini
    elif [ "${MODE}" == "fb" ] | [ "${MODE}" == "framebuffer" ]; then
        print_step_header "Configure container to use a virtual framebuffer as the X server"
        # Disable xorg supervisord script
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xorg.ini
        # Enable xvfb supervisord script
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/xvfb.ini
    else
        print_step_header "Configure container with no X server"
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xorg.ini
    fi

    # Enable KB/Mouse input capture with Xorg if configured
    if [ ${ENABLE_EVDEV_INPUTS:-} = "true" ]; then
        print_step_header "Enabling evdev input class on pointers, keyboards, touchpads, touch screens, etc."
        cp -f /usr/share/X11/xorg.conf.d/10-evdev.conf /etc/X11/xorg.conf.d/10-evdev.conf
    else
        print_step_header "Leaving evdev inputs disabled"
    fi
    
    # Configure dummy config if no monitor is connected
    if ([ "X${monitor_connected}" = "X" ] || [ "${FORCE_X11_DUMMY_CONFIG}" = "true" ]); then 
        print_step_header "No monitors connected. Installing dummy xorg.conf"
        # Use a dummy display input
        cp -f /templates/xorg/xorg.dummy.conf /etc/X11/xorg.conf
    else
        echo "WARNING: This fork expects you to run with FORCE_X11_DUMMY_CONFIG=true. You are running an unsupported configuration."
    fi
}

if ([ "${MODE}" != "s" ] && [ "${MODE}" != "secondary" ]); then
    print_header "Generate default xorg.conf"
    configure_x_server
fi

echo -e "\e[34mDONE\e[0m"
