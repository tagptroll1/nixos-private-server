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
}
