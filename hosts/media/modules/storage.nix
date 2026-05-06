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
  # library directory. The storage template puts user.storageLabel as
  # the first path segment (`library/<label>/<y>/<MM>/<filename>`), so
  # we mirror those label paths to the matching dataset on home02.
  bind = source: target: {
    ${target} = {
      device = source;
      fsType = "none";
      options = [ "bind" "x-systemd.requires-mounts-for=${source}" ];
    };
  };

  # Storage labels assigned to each Immich user. Adding a user means:
  # set their account's Storage Label to a new entry here, then add the
  # bind mount + tmpfiles entry below.
  labels = {
    tagp = "tagp";
    karoline = "karoline";
  };
in {
  fileSystems =
    (virtiofs "tagp"     "/mnt/tagp")
    // (virtiofs "karoline" "/mnt/karoline")
    // (virtiofs "media"  "/mnt/media")
    // (bind "/mnt/tagp/photos" "/var/lib/immich/library/${labels.tagp}")
    // (bind "/mnt/karoline/photos" "/var/lib/immich/library/${labels.karoline}");

  systemd.tmpfiles.settings = {
    "10-immich-library" = {
      "/var/lib/immich".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      "/var/lib/immich/library".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      "/var/lib/immich/library/${labels.tagp}".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
      "/var/lib/immich/library/${labels.karoline}".d = {
        user = "immich"; group = "immich"; mode = "0750";
      };
    };
  };
}
