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
}
