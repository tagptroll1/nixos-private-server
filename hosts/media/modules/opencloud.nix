{ config, pkgs, ... }: {
  fileSystems."/mnt/cloud" = {
    device = "cloud";
    fsType = "virtiofs";
    options = [ "defaults" "nofail" "x-systemd.device-timeout=10s" ];
  };

  # uid 1002 + gid 1002. On home02, gid 1002 is the existing `family` group
  # (members: tagp, karoline) — chosen deliberately so files written by the
  # opencloud container appear group-owned by `family` on the NAS side,
  # letting both human users read/write directly via group perm if needed.
  users.users.opencloud = {
    isSystemUser = true;
    uid = 1002;
    group = "family";
  };
  users.groups.family.gid = 1002;

  systemd.tmpfiles.settings."10-opencloud" = {
    "/mnt/cloud/config".d = { user = "opencloud"; group = "family"; mode = "0770"; };
    "/mnt/cloud/data".d   = { user = "opencloud"; group = "family"; mode = "0770"; };
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  # Shared bridge network so opencloud + collaboration + collabora can reach
  # each other by container name on internal ports (nats registry, gRPC,
  # WOPI). Without this they each live in their own netns and can only talk
  # via the public Caddy URL — which doesn't expose the internal services.
  systemd.services.podman-network-opencloud = {
    description = "Create podman network for opencloud stack";
    wantedBy = [ "multi-user.target" ];
    after = [ "podman.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      ${pkgs.podman}/bin/podman network exists opencloud-net || \
        ${pkgs.podman}/bin/podman network create opencloud-net
    '';
  };

  virtualisation.oci-containers.containers = {
    opencloud = {
      image = "opencloudeu/opencloud-rolling:6.1.0";
      ports = [ "127.0.0.1:9200:9200" ];
      user = "1002:1002";
      environment = {
        OC_URL = "https://cloud.ybmn.no";
        OC_INSECURE = "false";
        PROXY_TLS = "false";
        STORAGE_USERS_DRIVER = "posix";
        STORAGE_USERS_ID_CACHE_STORE = "nats-js-kv";
        STORAGE_USERS_POSIX_ROOT = "/var/lib/opencloud/storage";
        OC_PASSWORD_POLICY_MIN_CHARACTERS = "12";
        IDM_CREATE_DEMO_USERS = "false";
        PROXY_ENABLE_BASIC_AUTH = "false";
      };
      # Sops decrypts each YAML value verbatim into a file whose content is
      # the entire `KEY=value` line(s), so the decrypted secret is directly
      # envFile-compatible. shared_env holds the internal opencloud secrets
      # (jwt, machine-auth, transfer) that BOTH opencloud and the collaboration
      # service must agree on — same file mounted on both containers.
      environmentFiles = [
        config.sops.secrets."opencloud/shared_env".path
        config.sops.secrets."opencloud/admin_env".path
      ];
      volumes = [
        "/mnt/cloud/config:/etc/opencloud"
        "/mnt/cloud/data:/var/lib/opencloud"
      ];
      extraOptions = [ "--network=opencloud-net" ];
    };

    opencloud-collaboration = {
      image = "opencloudeu/opencloud-rolling:6.1.0";
      cmd = [ "collaboration" "server" ];
      ports = [ "127.0.0.1:9300:9300" ];
      user = "1002:1002";
      environment = {
        COLLABORATION_APP_NAME = "Collabora";
        COLLABORATION_APP_PRODUCT = "Collabora";
        COLLABORATION_APP_ADDR = "https://collabora.ybmn.no";
        COLLABORATION_APP_INSECURE = "false";
        COLLABORATION_WOPI_SRC = "https://wopi.ybmn.no";
        COLLABORATION_HTTP_ADDR = "0.0.0.0:9300";
        OC_URL = "https://cloud.ybmn.no";
        # Talk to opencloud's internal nats registry via container DNS name
        # on the shared network instead of bouncing through Caddy.
        MICRO_REGISTRY = "nats-js-kv";
        MICRO_REGISTRY_ADDRESS = "opencloud:9233";
      };
      environmentFiles = [
        config.sops.secrets."opencloud/shared_env".path
      ];
      dependsOn = [ "opencloud" ];
      extraOptions = [ "--network=opencloud-net" ];
    };

    collabora = {
      image = "collabora/code:25.04.9.4.1";
      ports = [ "127.0.0.1:9980:9980" ];
      environment = {
        aliasgroup1 = "https://wopi.ybmn.no";
        DONT_GEN_SSL_CERT = "YES";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true --o:net.frame_ancestors=cloud.ybmn.no --o:welcome.enable=false";
        server_name = "collabora.ybmn.no";
      };
      environmentFiles = [
        config.sops.secrets."opencloud/collabora_env".path
      ];
      extraOptions = [ "--network=opencloud-net" ];
    };
  };
}
