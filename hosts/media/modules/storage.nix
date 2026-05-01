{ ... }:
let
  # virtiofs tags configured on the Proxmox host side as Directory Mappings.
  virtiofs = tag: target: {
    ${target} = {
      device = tag;
      fsType = "virtiofs";
      options = [ "defaults" "nofail" "x-systemd.device-timeout=10s" ];
    };
  };

  # Bind mounts splice host-owned ZFS datasets into Immich's per-user
  # library directory. Immich segregates by user UUID by default
  # (no storage template needed); we map each UUID-named subdir to the
  # matching dataset on home02 so existing restic→Hetzner backups pick
  # the photos up unchanged.
  bind = source: target: {
    ${target} = {
      device = source;
      fsType = "none";
      options = [ "bind" "x-systemd.requires-mounts-for=${source}" ];
    };
  };

  # Immich user UUIDs (visible in admin → Users, or each user's Account
  # Settings → User ID). Add an entry here when a new user is created.
  users = {
    tagp = "e4cd2c79-7486-47b8-9812-de4588a69db0";
    # karoline = "<uuid>";  # fill in after creating the account
  };
in {
  fileSystems =
    (virtiofs "tagp"     "/mnt/tagp")
    // (virtiofs "karoline" "/mnt/karoline")
    // (bind "/mnt/tagp/photos" "/var/lib/immich/library/${users.tagp}");
    # // (bind "/mnt/karoline/photos" "/var/lib/immich/library/${users.karoline}");

  systemd.tmpfiles.settings = {
    "10-immich-library" = {
      "/var/lib/immich".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      "/var/lib/immich/library".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      "/var/lib/immich/library/${users.tagp}".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      # "/var/lib/immich/library/${users.karoline}".d = {
      #   user = "immich"; group = "immich"; mode = "0750";
      # };
    };
  };
}
