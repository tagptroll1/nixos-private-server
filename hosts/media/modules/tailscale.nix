{ ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Subnet router: needs IP forwarding (server) so other tailnet nodes
    # can reach 10.2.10.0/24 via this node.
    useRoutingFeatures = "server";
  };

  # First-time bring-up:
  #   sudo tailscale up --advertise-routes=10.2.10.0/24
  #   then approve the route in the Tailscale admin console.
  # Set up split DNS in admin: ybmn.no -> 10.2.10.1 (MikroTik)
}
