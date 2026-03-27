{ config, pkgs, ... }:

let
	webRoot       = "/var/www";
	wordpressRoot = "${webRoot}/wordpress";
in
{
	# ── Database ───────────────────────────────────────────────────────────────
	services.mysql = {
		enable  = true;
		package = pkgs.mariadb;
		ensureDatabases = [ "wordpress" ];
		ensureUsers = [{
			name = "wordpress";
			ensurePermissions = {
				"wordpress.*" = "ALL PRIVILEGES";
			};
		}];
	};

	# ── PHP-FPM ────────────────────────────────────────────────────────────────
	services.phpfpm.pools.wordpress = {
		user  = "nginx";
		group = "nginx";
		settings = {
			"listen.owner"         = "nginx";
			"listen.group"         = "nginx";
			"pm"                   = "dynamic";
			"pm.max_children"      = 10;
			"pm.start_servers"     = 2;
			"pm.min_spare_servers" = 1;
			"pm.max_spare_servers" = 3;
		};
		phpPackage = pkgs.php83.buildEnv {
			extensions = ({ enabled, all }: enabled ++ (with all; [
				mysqli pdo_mysql curl gd mbstring xml zip opcache
			]));
		};
	};

	# ── Nginx virtual hosts ────────────────────────────────────────────────────
	services.nginx.enable = true;

	# Custom log format with request_time for Prometheus nginxlog exporter
	services.nginx.commonHttpConfig = ''
		log_format wordpress_combined '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time';
	'';

	# Internal WordPress interface (exposed via Pangolin tunnel on port 8080)
	services.nginx.virtualHosts."wordpress-pangolin" = {
		listen = [{ addr = "0.0.0.0"; port = 8080; }];
		root   = wordpressRoot;

		extraConfig = ''
			server_tokens off;
			add_header X-Frame-Options "SAMEORIGIN" always;
			add_header X-Content-Type-Options "nosniff" always;
			add_header X-XSS-Protection "1; mode=block" always;
			add_header Referrer-Policy "strict-origin-when-cross-origin" always;
			access_log /var/log/nginx/wordpress_access.log wordpress_combined;
		'';

		locations."/" = {
			index       = "index.php";
			extraConfig = "try_files $uri $uri/ /index.php?$args;";
		};

		locations."~ \\.php$" = {
			extraConfig = ''
				fastcgi_pass  unix:${config.services.phpfpm.pools.wordpress.socket};
				fastcgi_index index.php;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				include       ${pkgs.nginx}/conf/fastcgi_params;
			'';
		};

		locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$" = {
			extraConfig = "expires max; log_not_found off;";
		};

		locations."= /xmlrpc.php"                                           = { extraConfig = "deny all;"; };
		locations."~* ^/(readme|license|wp-config-sample)\\.(html|txt|php)$" = { extraConfig = "deny all;"; };
		locations."= /wp-config.php"                                        = { extraConfig = "deny all;"; };
		locations."~ /\\."                                                   = { extraConfig = "deny all;"; };
		locations."~* /wp-content/uploads/.*\\.php$"                        = { extraConfig = "deny all;"; };
		locations."~* ^/wp-includes/.*\\.php$"                              = { extraConfig = "deny all;"; };
	};

	# LAN admin interface — HTTPS direct access via local DNS
	services.nginx.virtualHosts."admin.sletteposten.no" = {
		onlySSL = true;
		listen  = [{ addr = "0.0.0.0"; port = 443; ssl = true; }];
		root    = wordpressRoot;

		useACMEHost = "admin.sletteposten.no";

		extraConfig = ''
			server_tokens off;
			add_header X-Frame-Options "SAMEORIGIN" always;
			add_header X-Content-Type-Options "nosniff" always;
			add_header X-XSS-Protection "1; mode=block" always;
			add_header Referrer-Policy "strict-origin-when-cross-origin" always;
			add_header Strict-Transport-Security "max-age=31536000" always;
		'';

		locations."/" = {
			index       = "index.php";
			extraConfig = "try_files $uri $uri/ /index.php?$args;";
		};

		locations."~ \\.php$" = {
			extraConfig = ''
				fastcgi_pass  unix:${config.services.phpfpm.pools.wordpress.socket};
				fastcgi_index index.php;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				include       ${pkgs.nginx}/conf/fastcgi_params;
			'';
		};

		locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$" = {
			extraConfig = "expires max; log_not_found off;";
		};

		locations."= /xmlrpc.php"                                           = { extraConfig = "deny all;"; };
		locations."~* ^/(readme|license|wp-config-sample)\\.(html|txt|php)$" = { extraConfig = "deny all;"; };
		locations."= /wp-config.php"                                        = { extraConfig = "deny all;"; };
		locations."~ /\\."                                                   = { extraConfig = "deny all;"; };
		locations."~* /wp-content/uploads/.*\\.php$"                        = { extraConfig = "deny all;"; };
		locations."~* ^/wp-includes/.*\\.php$"                              = { extraConfig = "deny all;"; };
	};

	# ACME cert for the WordPress admin panel
	security.acme.certs."admin.sletteposten.no" = {
		domain = "admin.sletteposten.no";
		dnsProvider = "domeneshop";
		credentialFiles = {
			"DOMENESHOP_API_TOKEN_FILE" = config.sops.secrets."domeneshop_api_token".path;
			"DOMENESHOP_API_SECRET_FILE" = config.sops.secrets."domeneshop_api_secret".path;
		};
		group = "nginx";
	};

	users.users.nginx.extraGroups = [ "acme" ];

	# ── Directory setup ────────────────────────────────────────────────────────
	systemd.tmpfiles.rules = [
		"d ${wordpressRoot} 0755 nginx nginx - -"
	];

	# ── One-shot WordPress deploy service ──────────────────────────────────────
	systemd.services."setup-wordpress" = {
		description = "Deploy WordPress core and Daily News Blog theme";
		after       = [ "network-online.target" "mysql.service" ];
		wants       = [ "network-online.target" ];
		wantedBy    = [ "multi-user.target" ];

		# Only runs if wp-config.php doesn't exist yet
		unitConfig.ConditionPathExists = "!${wordpressRoot}/wp-config.php";

		path = with pkgs; [ curl gnutar gzip unzip coreutils ];

		serviceConfig = {
			Type            = "oneshot";
			User            = "nginx";
			Group           = "nginx";
			RemainAfterExit = true;
		};

		script = ''
			set -e
			WP_DIR="${wordpressRoot}"

			echo "Downloading WordPress core..."
			curl -fsSL https://wordpress.org/latest.tar.gz \
				| tar -xz --strip-components=1 -C "$WP_DIR"

			echo "Downloading Minimalistix parent theme..."
			curl -fsSL "https://downloads.wordpress.org/theme/minimalistix.latest-stable.zip" \
				-o /tmp/minimalistix.zip
			unzip -q /tmp/minimalistix.zip -d "$WP_DIR/wp-content/themes/"
			rm /tmp/minimalistix.zip

			echo "Downloading Daily News Blog theme..."
			curl -fsSL "https://downloads.wordpress.org/theme/daily-news-blog.latest-stable.zip" \
				-o /tmp/daily-news-blog.zip
			unzip -q /tmp/daily-news-blog.zip -d "$WP_DIR/wp-content/themes/"
			rm /tmp/daily-news-blog.zip

			cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
			sed -i "s/database_name_here/wordpress/" "$WP_DIR/wp-config.php"
			sed -i "s/username_here/wordpress/"       "$WP_DIR/wp-config.php"
			sed -i "s/password_here//"                "$WP_DIR/wp-config.php"

			# Dynamic multi-domain URL detection (Pangolin + direct LAN access)
			sed -i "/require_once.*wp-settings\.php/i\\
\\
/* Dynamic multi-domain URL detection */\\
if ( isset( \$_SERVER['HTTP_HOST'] ) ) {\\
    \$scheme = ( ! empty( \$_SERVER['HTTPS'] ) \&\& \$_SERVER['HTTPS'] !== 'off' )\\
              || ( isset( \$_SERVER['HTTP_X_FORWARDED_PROTO'] )\\
                   \&\& \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' )\\
              ? 'https' : 'http';\\
    define( 'WP_HOME',    \$scheme . '://' . \$_SERVER['HTTP_HOST'] );\\
    define( 'WP_SITEURL', \$scheme . '://' . \$_SERVER['HTTP_HOST'] );\\
}" "$WP_DIR/wp-config.php"

			find "$WP_DIR" -type d -exec chmod 755 {} \;
			find "$WP_DIR" -type f -exec chmod 644 {} \;

			echo "WordPress setup complete."
		'';
	};
}
