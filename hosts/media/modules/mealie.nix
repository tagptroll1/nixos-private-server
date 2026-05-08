{ ... }: {
  # State lives under the `tagp` virtiofs share so it gets backed up alongside
  # photos. Pre-create the directory on home02 before the first rebuild:
  #   mkdir -p /<tagp-dataset>/appdata/mealie && chmod 0777 …
  # Mealie runs with DynamicUser=true, so systemd allocates a stable uid per
  # service name. After first boot you can tighten ownership by chowning the
  # directory on home02 to whatever uid the `mealie` user resolved to inside
  # the VM (`getent passwd mealie`).
  fileSystems."/var/lib/mealie" = {
    device = "/mnt/tagp/appdata/mealie";
    fsType = "none";
    options = [ "bind" "x-systemd.requires-mounts-for=/mnt/tagp" ];
  };

  services.mealie = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9925;
    database.createLocally = true;
    settings = {
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://recipe.ybmn.no";
    };
  };
}
