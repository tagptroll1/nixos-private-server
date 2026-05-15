{ config, pkgs, ... }: {
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/tagptroll1/caddy-dns-domeneshop@v0.1.6"
      ];
      # v0.1.6: reconstruct FQDN from libdns relative-name + zone before
      # matching the owned domain list (v0.1.5 still failed because
      # certmagic strips the zone tail before calling the provider).
      # First build will fail with hash mismatch — paste new sha256.
      hash = "sha256-/ZpUa2CVlrv9lHPkkEa1zmtuyE3Do13/eMiiyIY57rg=";
    };

    globalConfig = ''
      debug
      acme_dns domeneshop {
        token  {env.DOMENESHOP_API_TOKEN}
        secret {env.DOMENESHOP_API_SECRET}
      }
    '';

    virtualHosts =
      let
        # LAN + Tailscale CGNAT + loopback. Caddy uses these matchers to
        # 403 anything else, since *.ybmn.no resolves on split-DNS only.
        trustedMatcher = ''
          @trusted client_ip 10.2.10.0/24 192.168.0.0/24 100.64.0.0/10 127.0.0.1/8
        '';
        tlsBlock = ''
          tls {
            dns domeneshop {
              token  {env.DOMENESHOP_API_TOKEN}
              secret {env.DOMENESHOP_API_SECRET}
            }
          }
        '';
        gated = upstream: ''
          ${tlsBlock}
          ${trustedMatcher}
          handle @trusted {
            reverse_proxy ${upstream}
          }
          respond 403
        '';
      in {
      "immich.ybmn.no".extraConfig = ''
        reverse_proxy 127.0.0.1:2283
      '';
      "jellyfin.ybmn.no".extraConfig = ''
        reverse_proxy 127.0.0.1:8096
      '';
      # TODO: add `seer.ybmn.no` A/CNAME record in domeneshop before this
      # vhost can serve traffic — Caddy will otherwise fail ACME DNS-01.
      "seer.ybmn.no".extraConfig    = gated "127.0.0.1:5055";
      "sonarr.ybmn.no".extraConfig   = gated "127.0.0.1:8989";
      "radarr.ybmn.no".extraConfig   = gated "127.0.0.1:7878";
      "prowlarr.ybmn.no".extraConfig = gated "127.0.0.1:9696";
      "bazarr.ybmn.no".extraConfig   = gated "127.0.0.1:6767";
      # qBittorrent lives in the wg netns; reachable at the namespace IP
      # from the host. Confirm with `ip -n wg a` after first boot if 192.168.15.1
      # ever drifts.
      "qbit.ybmn.no".extraConfig     = gated "192.168.15.1:8080";
      "recipe.ybmn.no".extraConfig = gated "127.0.0.1:9925";
      "cloud.ybmn.no".extraConfig     = gated "127.0.0.1:9200";
      "collabora.ybmn.no".extraConfig = gated "127.0.0.1:9980";
      "wopi.ybmn.no".extraConfig      = gated "127.0.0.1:9300";
    };
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.secrets."caddy/domeneshop_token".path;
  };
}
