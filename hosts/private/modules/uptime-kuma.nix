{ ... }:
{
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
      # Bind to localhost only — Caddy is the only consumer
      HOST = "127.0.0.1";
    };
  };
  # No user declaration needed — DynamicUser=true handles it
  # Data is stored at /var/lib/private/uptime-kuma (systemd StateDirectory)
}
