{ ... }:
{
  # Stable symlink for the Sonoff ZBDongle-E (EFR32MG21 + CP2102N, VID:PID 10c4:ea60).
  # Without this, the dongle races with other USB-serial devices for /dev/ttyUSB0.
  # Verify on the host with: lsusb | grep 10c4
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="ttyZigbee", MODE="0660", GROUP="dialout"
  '';

  services.home-assistant = {
    enable = true;
    openFirewall = false;

    extraComponents = [
      "default_config" # required for onboarding
      "met"            # weather/sun integration
      "zha"            # Zigbee Home Automation — uses Sonoff ZBDongle-E via /dev/ttyZigbee
                       # ZBDongle-E uses ezsp radio protocol (auto-detected by ZHA during UI setup)
                       # Automatically adds hass to dialout group and allows ttyUSB/ttyACM devices
    ];

    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
      };

      http = {
        server_host = "127.0.0.1";
        server_port = 8123;
        # Required when behind Caddy — passes real client IP
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };

      # Keep automations/scripts/scenes UI-editable (HA writes these files at runtime)
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
  };
}
