{ ... }: {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;

    # Managed Postgres + Redis (defaults). Postgres 16 is required while
    # pgvecto.rs is still enabled — VectorChord is also enabled in parallel
    # for the 25.11+ migration path.
    database.enable = true;
    redis.enable = true;

    machine-learning.enable = true;

    # Whitelist NVIDIA device nodes so the hardened service can reach the
    # GTX 1070 for ML inference. PrivateDevices stays enabled.
    accelerationDevices = [
      "/dev/nvidia0"
      "/dev/nvidiactl"
      "/dev/nvidia-uvm"
      "/dev/nvidia-uvm-tools"
      "/dev/nvidia-modeset"
    ];

    settings = null;
  };

  # Pin the in-VM immich uid/gid to home02's tagp (uid=1001, gid=1001).
  # Virtiofs preserves uids across the VM↔host boundary; matching them
  # makes new files written by Immich appear owned by `tagp` on home02.
  # Multi-user note: when karoline is added, her photos will also be
  # owned by tagp on the host because virtiofs maps a single uid per
  # share. Revisit (per-share uid mapping or shared `family` group)
  # once she has her own dataset routing.
  users.users.immich.uid = 1001;
  users.groups.immich.gid = 1001;
}
