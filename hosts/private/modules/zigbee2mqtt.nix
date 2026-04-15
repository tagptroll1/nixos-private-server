{ lib, hostConfig, ... }:
{
  # Mosquitto — local MQTT broker, only accessible from localhost
  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "127.0.0.1";
      port = 1883;
      settings.allow_anonymous = true;
      omitPasswordAuth = true;
    }];
  };

  # The NixOS mosquitto module generates an empty ACL file when no users are defined.
  # An empty ACL file silently denies all topic access to everyone — override it.
  environment.etc."mosquitto/acl-0.conf" = lib.mkForce {
    text = "topic readwrite #\n";
    mode = "0600";
    user = "mosquitto";
    group = "mosquitto";
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      # homeassistant.enabled is auto-set to true because services.home-assistant.enable = true
      permit_join = false; # toggle in the frontend UI when pairing new devices

      serial = {
        port = "/dev/ttyZigbee";
        adapter = "ember"; # ZBDongle-E uses EFR32MG21 — ember is the current driver (ezsp deprecated in z2m 2.x)
      };

      mqtt = {
        server = "mqtt://localhost:1883";
        base_topic = "zigbee2mqtt";
      };

      frontend = {
        enabled = true;
        host = hostConfig.ip;
        port = 8124;
      };
    };
  };
}
