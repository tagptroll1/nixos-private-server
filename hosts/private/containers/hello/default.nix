{ pkgs, hostConfig, ... }:
let
  serveScript = pkgs.writeShellScriptBin "serve.sh" ''
		while true; do
			{ 
				printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nHello, world!\nThe secret word is: %s\r\n" \
					"$SECRET_PHRASE"
			} | socat -u STDIN TCP-LISTEN:8080,reuseaddr
		done
	'';


  image = pkgs.dockerTools.buildImage {
		name = "hello-server";
		tag = "latest";
		copyToRoot = pkgs.buildEnv {
			name = "hello-env";
			paths = [ pkgs.bash pkgs.coreutils pkgs.socat serveScript ];
			pathsToLink = [ "/bin" ];
		};
		config.Cmd = [ "/bin/bash" "/bin/serve.sh" ];
	};
in
{
  virtualisation.quadlet.containers.hello = {
    autoStart = true;

    containerConfig = {
			userns = "keep-id"; 
      # use the nix-built image directly — no registry pull
      image = "docker-archive:${image}";

      # dedicated isolated network, not the default podman bridge
      networks = [ "hello-net" ];

      # bind only to your VLAN IP, not 0.0.0.0
      publishPorts = [ "${hostConfig.ip}:8080:8080" ];

      # inject secret as env vars from the sops-managed env file
      environmentFiles = [ "/run/secrets/hello/secret" ];

      # hardening
      readOnly = true;
      noNewPrivileges = true;
      dropCapabilities = [ "ALL" ];

      # resource limits
      memory = "64m";
    };

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10";
      # Remove any leftover container from a previous generation before starting.
      # The '-' prefix tells systemd to ignore failure (no container = fine).
      ExecStartPre = "-/run/current-system/sw/bin/podman rm -f hello";
    };
  };

  virtualisation.quadlet.networks.hello-net = {
    networkConfig = {
      subnets = [ "10.89.0.0/24" ];
      # no external access from within the container
      internal = true;
    };
  };
}
