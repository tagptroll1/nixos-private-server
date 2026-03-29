{ pkgs, config, ... }:

let
  appDir  = "/var/lib/peterssoncoffee";
  appPort = 3000;
in
{
  # ── Runtime service (build on start, then serve) ─────────────────────────────
  systemd.services."peterssoncoffee" = {
    description = "petersson.coffee SvelteKit site";
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];

    path = with pkgs; [ git nodejs coreutils ];

    environment = {
      NODE_ENV = "production";
      HOST     = "0.0.0.0";
      PORT     = toString appPort;
      ORIGIN   = "https://yesbutmaybe.no";
      HOME     = appDir;
    };

    preStart = ''
      set -e
      if [ ! -d ${appDir}/.git ]; then
        git clone https://github.com/tagptroll1/peterssoncoffee.git ${appDir}
      else
        git -C ${appDir} fetch origin
        git -C ${appDir} reset --hard origin/master
      fi
      cd ${appDir}
      npm ci --prefer-offline
      npm run build
    '';

    serviceConfig = {
      User             = "peterssoncoffee";
      Group            = "peterssoncoffee";
      WorkingDirectory = appDir;
      ExecStart        = "${pkgs.nodejs}/bin/node ${appDir}/build/index.js";
      Restart          = "on-failure";
      RestartSec       = "10s";
      TimeoutStartSec  = "300";
      ProtectSystem    = "full";
      ReadWritePaths   = [ appDir ];
			EnvironmentFile  = config.sops.secrets."github_token".path;
    };
  };

  # ── Daily update — restarts the service which triggers a rebuild ──────────────
  systemd.services."peterssoncoffee-update" = {
    description = "Rebuild and redeploy petersson.coffee";
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart peterssoncoffee.service";
    };
  };

  systemd.timers."peterssoncoffee-update" = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnCalendar        = "daily";
      RandomizeDelaySec = "30min";
      Persistent        = true;
    };
  };

  # ── App directory ─────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${appDir} 0755 peterssoncoffee peterssoncoffee - -"
  ];
}
