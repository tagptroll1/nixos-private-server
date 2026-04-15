{ ... }:
{
  # Mosquitto — local MQTT broker, only accessible from localhost
  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "127.0.0.1";
      port = 1883;
      settings.allow_anonymous = true;
    }];
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      # homeassistant.enabled is auto-set to true because services.home-assistant.enable = true
      permit_join = false; # toggle in the frontend UI when pairing new devices

      serial = {
        port = "/dev/ttyZigbee";
        adapter = "ezsp"; # ZBDongle-E uses EFR32MG21 (EZSP protocol)
      };

      mqtt = {
        server = "mqtt://localhost:1883";
        base_topic = "zigbee2mqtt";
      };

      frontend = {
        enabled = true;
        host = "127.0.0.1";
        port = 8080;
      };
    };
  };
}
