{ pkgs, ... }: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;    # don't alias docker -> podman, be explicit
    defaultNetwork.settings.dns_enabled = true;
  };

	virtualisation.quadlet.enable = true;

  # allow rootless containers to use low ports if ever needed
  # and ensure cgroup v2 is available for proper resource tracking
  boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];

  # podman auto-update runs daily via systemd timer, this enables it
  systemd.timers."podman-auto-update" = {
    timerConfig.OnCalendar = "daily";
    timerConfig.Persistent = true;
    wantedBy = [ "timers.target" ];
  };

  # ensure the auto-update service exists
  systemd.services."podman-auto-update" = {
    serviceConfig.Type = "oneshot";
  };

  environment.systemPackages = [ pkgs.podman ];
}
