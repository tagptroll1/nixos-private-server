{
  private = {
    hostname = "private";
    interface = "ens18";
    ip = "10.0.20.5";
    gateway = "10.0.20.1";
    prefixLength = 24;
		nameservers = [ "8.8.8.8" "1.1.1.1" ];

		systemData = "/var/lib";
		userData = "/home/tagp/.local/share";
  };

  public = {
    hostname = "public";
    interface = "ens18";
    ip = "10.0.10.10";
    gateway = "10.0.10.1";
    prefixLength = 24;
		nameservers = [ "8.8.8.8" "1.1.1.1" ];

		systemData = "/var/lib";
		userData = "/home/tagp/.local/share";
  };

  media = {
    hostname = "media";
    interface = "ens18";
    ip = "10.2.10.10";
    gateway = "10.2.10.1";
    prefixLength = 24;
		# Public resolvers only — MikroTik treats ybmn.no as authoritative for
		# its own static entries and returns NXDOMAIN for everything else in
		# the zone (including _acme-challenge.* records that Caddy needs to
		# verify during DNS-01 challenges). Match private/public host config.
		nameservers = [ "1.1.1.1" "8.8.8.8" ];

		systemData = "/var/lib";
		userData = "/home/tagp/.local/share";
  };
}
