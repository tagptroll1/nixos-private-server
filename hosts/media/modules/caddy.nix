{ config, pkgs, ... }: {
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/tagptroll1/caddy-dns-domeneshop@v0.1.7"
      ];
      # v0.1.7: implements RecordSetter so each Present() atomically
      # replaces the _acme-challenge TXT RRset. Previously stale TXTs
      # accumulated alongside the new one, causing certmagic's
      # checkAuthoritativeNss to time out with `last error: <nil>`.
      hash = "sha256-cyHKghK8/i3DIg+Ja18Pa4R+gTh93FQFF2nly4KnKgk=";
    };

    logFormat = "level DEBUG";
    globalConfig = ''
      debug
      acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
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
        # Query the zone's authoritative nameservers (hyp.net) directly for
        # the DNS-01 propagation check. Public anycast resolvers like
        # 1.1.1.1 have inconsistent cache state across POPs — the TXT
        # appears and disappears between polls, so Caddy never confirms
        # propagation and times out with `last error: <nil>`. Authoritative
        # servers always reflect the source of truth.
        tlsBlock = ''
          tls {
            dns domeneshop {
              token  {env.DOMENESHOP_API_TOKEN}
              secret {env.DOMENESHOP_API_SECRET}
            }
            resolvers 151.249.124.1 192.174.68.10 151.249.126.3
            propagation_delay 30s
            propagation_timeout 5m
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
