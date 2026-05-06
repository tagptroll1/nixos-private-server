{ ... }: {
  services.immich-public-proxy = {
    enable       = true;
    immichUrl    = "http://127.0.0.1:2283";
    port         = 3000;
    openFirewall = false;
  };

  # Defense-in-depth: only the public VM (10.0.10.10) may hit IPP, even if
  # the MikroTik forward allowlist is misconfigured. Public→media:3000 is
  # also gated at the router; this is the second lock.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 10.0.10.10 -p tcp --dport 3000 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 10.0.10.10 -p tcp --dport 3000 -j nixos-fw-accept || true
  '';
}
