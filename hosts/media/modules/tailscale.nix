{ ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Subnet router: needs IP forwarding (server) so other tailnet nodes
    # can reach 10.2.10.0/24 via this node.
    useRoutingFeatures = "server";
    # Don't let Tailscale rewrite /etc/resolv.conf on this server. The
    # tailnet's split-DNS forwards ybmn.no to MikroTik, which treats the
    # zone as authoritative and returns NXDOMAIN for dynamic records like
    # _acme-challenge.* — breaking Caddy's DNS-01 ACME challenge. Media
    # VM doesn't need MagicDNS itself (clients keep using it for access).
    extraUpFlags = [ "--accept-dns=false" ];
  };

  # First-time bring-up:
  #   sudo tailscale up --advertise-routes=10.2.10.0/24 --accept-dns=false
  #   then approve the route in the Tailscale admin console.
  # Set up split DNS in admin: ybmn.no -> 10.2.10.1 (MikroTik)
}
