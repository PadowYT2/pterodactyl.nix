{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pterodactyl.panel;
  env =
    {
      APP_NAME = cfg.app.name;
      APP_ENV = cfg.app.env;
      APP_DEBUG = cfg.app.debug;
      APP_KEY =
        if cfg.app.keyFile != null
        then null
        else cfg.app.key;
      APP_TIMEZONE = cfg.app.timezone;
      APP_URL = cfg.app.url;
      APP_ENVIRONMENT_ONLY = cfg.app.environmentOnly;

      DB_HOST = cfg.database.host;
      DB_PORT = cfg.database.port;
      DB_DATABASE = cfg.database.name;
      DB_USERNAME = cfg.database.user;
      DB_PASSWORD =
        if cfg.database.passwordFile != null
        then null
        else cfg.database.password;

      REDIS_SCHEME =
        if cfg.redis.createLocally
        then "unix"
        else "tcp";
      REDIS_PATH =
        if cfg.redis.createLocally
        then config.services.redis.servers.${cfg.redis.name}.unixSocket
        else null;
      REDIS_HOST =
        if cfg.redis.createLocally
        then null
        else cfg.redis.host;
      REDIS_PORT =
        if cfg.redis.createLocally
        then null
        else cfg.redis.port;
      REDIS_PASSWORD =
        if cfg.redis.passwordFile != null
        then null
        else cfg.redis.password;

      CACHE_DRIVER = cfg.cacheDriver;
      QUEUE_CONNECTION = cfg.queueConnection;
      SESSION_DRIVER = cfg.sessionDriver;

      HASHIDS_SALT =
        if cfg.hashids.saltFile != null
        then null
        else cfg.hashids.salt;
      HASHIDS_LENGTH = cfg.hashids.length;

      MAIL_MAILER = cfg.mail.mailer;
      MAIL_HOST = cfg.mail.host;
      MAIL_PORT = cfg.mail.port;
      MAIL_USERNAME = cfg.mail.username;
      MAIL_PASSWORD =
        if cfg.mail.passwordFile != null
        then null
        else cfg.mail.password;
      MAIL_ENCRYPTION = cfg.mail.encryption;
      MAIL_FROM_ADDRESS = cfg.mail.fromAddress;
      MAIL_FROM_NAME = cfg.mail.fromName;

      TRUSTED_PROXIES = builtins.concatStringsSep "," cfg.trustedProxies;
      PTERODACTYL_TELEMETRY_ENABLED = cfg.telemetry.enable;
    }
    // cfg.extraEnvironment;

  php = pkgs.php83.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        bcmath
        curl
        dom
        gd
        mbstring
        mysqli
        opcache
        pdo
        pdo_mysql
        redis
        zip
      ]);
  };
in {
  options.services.pterodactyl.panel = {
    enable = mkEnableOption "Pterodactyl Panel";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl.panel;
      defaultText = "pkgs.pterodactyl.panel";
      description = "Pterodactyl Panel package to use";
    };

    user = mkOption {
      type = types.str;
      default = "pterodactyl-panel";
      description = "User to run the panel as";
    };

    group = mkOption {
      type = types.str;
      default = "pterodactyl-panel";
      description = "Group to run the panel as";
    };

    app = {
      name = mkOption {
        type = types.str;
        default = "Pterodactyl";
      };

      env = mkOption {
        type = types.str;
        default = "production";
      };

      debug = mkOption {
        type = types.bool;
        default = false;
      };

      key = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };

      timezone = mkOption {
        type = types.str;
        default = "UTC";
      };

      url = mkOption {
        type = types.str;
      };

      environmentOnly = mkOption {
        type = types.bool;
        default = false; # TODO: someday could be true?
      };
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
      };
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      port = mkOption {
        type = types.port;
        default = 3306;
      };
      name = mkOption {
        type = types.str;
        default = "panel";
      };
      user = mkOption {
        type = types.str;
        default = "pterodactyl";
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
    };

    redis = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
      };
      name = mkOption {
        type = types.str;
        default = "pterodactyl-panel";
      };
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      port = mkOption {
        type = types.port;
        default = 6379;
      };
    };

    cacheDriver = mkOption {
      type = types.str;
      default = "redis";
    };

    queueConnection = mkOption {
      type = types.str;
      default = "redis";
    };

    sessionDriver = mkOption {
      type = types.str;
      default = "redis";
    };

    hashids = {
      salt = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      saltFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      length = mkOption {
        type = types.int;
        default = 8;
      };
    };

    mail = {
      mailer = mkOption {
        type = types.str;
        default = "smtp";
      };
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      port = mkOption {
        type = types.port;
        default = 25;
      };
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      encryption = mkOption {
        type = types.str;
        default = "tls";
      };
      fromAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      fromName = mkOption {
        type = types.str;
        default = "Pterodactyl Panel";
      };
    };

    trustedProxies = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    telemetry.enable = mkOption {
      type = types.bool;
      default = true;
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };

    extraEnvironmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.app.key == null || cfg.app.keyFile == null;
        message = "cannot set both services.pterodactyl.panel.app.key and services.pterodactyl.panel.app.keyFile.";
      }
      {
        assertion = cfg.database.password == null || cfg.database.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.database.password and services.pterodactyl.panel.database.passwordFile.";
      }
      {
        assertion = cfg.redis.password == null || cfg.redis.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.redis.password and services.pterodactyl.panel.redis.passwordFile.";
      }
      {
        assertion = cfg.hashids.salt == null || cfg.hashids.saltFile == null;
        message = "cannot set both services.pterodactyl.panel.hashids.salt and services.pterodactyl.panel.hashids.saltFile.";
      }
      {
        assertion = cfg.mail.password == null || cfg.mail.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.mail.password and services.pterodactyl.panel.mail.passwordFile.";
      }
    ];

    services.mysql = optionalAttrs cfg.database.createLocally {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [cfg.database.name];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions = {
            "${cfg.database.name}.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    services.redis.servers."${cfg.redis.name}" = mkIf cfg.redis.createLocally ({
        enable = true;
      }
      // optionalAttrs (cfg.redis.password != null) {
        requirePass = cfg.redis.password;
      }
      // optionalAttrs (cfg.redis.passwordFile != null) {
        requirePassFile = cfg.redis.passwordFile;
      });

    systemd.services.pteroq = {
      description = "Pterodactyl Queue Worker";
      after = ["redis.service"];
      requires = ["redis.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        ExecStart = "${php}/bin/php ${cfg.package}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3";
        WorkingDirectory = cfg.package;
        Environment = mapAttrsToList (n: v: "${n}=${toString v}") (filterAttrs (n: v: v != null) env);
        EnvironmentFile = optional (cfg.extraEnvironmentFile != null) cfg.extraEnvironmentFile;
        LoadCredential =
          (optional (cfg.app.keyFile != null) "APP_KEY:${cfg.app.keyFile}")
          ++ (optional (cfg.database.passwordFile != null) "DB_PASSWORD:${cfg.database.passwordFile}")
          ++ (optional (cfg.redis.passwordFile != null) "REDIS_PASSWORD:${cfg.redis.passwordFile}")
          ++ (optional (cfg.hashids.saltFile != null) "HASHIDS_SALT:${cfg.hashids.saltFile}")
          ++ (optional (cfg.mail.passwordFile != null) "MAIL_PASSWORD:${cfg.mail.passwordFile}");
      };
    };

    services.phpfpm.pools."pterodactyl-panel" = {
      user = cfg.user;
      group = cfg.group;
      phpPackage = php;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "listen.group" = config.services.nginx.group;
        "pm" = "dynamic";
        "pm.max_children" = 5;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
      };
    };

    systemd.services."phpfpm-pterodactyl-panel" = {
      serviceConfig = {
        Environment = mapAttrsToList (n: v: "${n}=${toString v}") (filterAttrs (n: v: v != null) env);
        EnvironmentFile = optional (cfg.extraEnvironmentFile != null) cfg.extraEnvironmentFile;
        LoadCredential =
          (optional (cfg.app.keyFile != null) "APP_KEY:${cfg.app.keyFile}")
          ++ (optional (cfg.database.passwordFile != null) "DB_PASSWORD:${cfg.database.passwordFile}")
          ++ (optional (cfg.redis.passwordFile != null) "REDIS_PASSWORD:${cfg.redis.passwordFile}")
          ++ (optional (cfg.hashids.saltFile != null) "HASHIDS_SALT:${cfg.hashids.saltFile}")
          ++ (optional (cfg.mail.passwordFile != null) "MAIL_PASSWORD:${cfg.mail.passwordFile}");
      };
    };

    services.nginx = {
      enable = mkDefault true;
      virtualHosts."${builtins.replaceStrings ["https://" "http://"] ["" ""] cfg.app.url}" = {
        root = "${cfg.package}/public";
        extraConfig = ''
          index index.php;
          client_max_body_size 100m;
          client_body_timeout 120s;
          sendfile off;
        '';
        locations."/" = {
          extraConfig = ''
            try_files $uri $uri/ /index.php?$query_string;
          '';
        };
        locations."~ \\.php$" = {
          extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.pterodactyl-panel.socket};
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param HTTP_PROXY "";
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 300;
            include ${pkgs.nginx}/conf/fastcgi_params;
          '';
        };
      };
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = optionals cfg.redis.createLocally ["redis"];
    };
    users.groups.${cfg.group} = {};
  };
}
