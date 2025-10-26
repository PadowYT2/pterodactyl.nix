{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pterodactyl.panel;

  secrets = lib.filter (s: s.file != null) [
    {
      name = "APP_KEY";
      file = cfg.app.keyFile;
    }
    {
      name = "DB_PASSWORD";
      file = cfg.database.passwordFile;
    }
    {
      name = "REDIS_PASSWORD";
      file = cfg.redis.passwordFile;
    }
    {
      name = "HASHIDS_SALT";
      file = cfg.hashids.saltFile;
    }
    {
      name = "MAIL_PASSWORD";
      file = cfg.mail.passwordFile;
    }
  ];

  env =
    (filterAttrs (n: v: v != null) {
      APP_NAME = cfg.app.name;
      APP_ENV = cfg.app.env;
      APP_DEBUG = cfg.app.debug;
      APP_KEY = cfg.app.key;
      APP_TIMEZONE = cfg.app.timezone;
      APP_URL = cfg.app.url;
      APP_ENVIRONMENT_ONLY = cfg.app.environmentOnly;

      DB_CONNECTION = "mysql";
      DB_HOST =
        if cfg.database.createLocally
        then "localhost"
        else cfg.database.host;
      DB_PORT = cfg.database.port;
      DB_DATABASE = cfg.database.name;
      DB_USERNAME = cfg.database.user;
      DB_PASSWORD = cfg.database.password;
      DB_SOCKET =
        if cfg.database.createLocally
        then "/run/mysqld/mysqld.sock"
        else null;

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
      REDIS_PASSWORD = cfg.redis.password;

      CACHE_DRIVER = cfg.cacheDriver;
      QUEUE_CONNECTION = cfg.queueConnection;
      SESSION_DRIVER = cfg.sessionDriver;

      HASHIDS_SALT = cfg.hashids.salt;
      HASHIDS_LENGTH = cfg.hashids.length;

      MAIL_MAILER = cfg.mail.mailer;
      MAIL_HOST = cfg.mail.host;
      MAIL_PORT = cfg.mail.port;
      MAIL_USERNAME = cfg.mail.username;
      MAIL_PASSWORD = cfg.mail.password;
      MAIL_ENCRYPTION = cfg.mail.encryption;
      MAIL_FROM_ADDRESS = cfg.mail.fromAddress;
      MAIL_FROM_NAME = cfg.mail.fromName;

      TRUSTED_PROXIES = builtins.concatStringsSep "," cfg.trustedProxies;
      PTERODACTYL_TELEMETRY_ENABLED = cfg.telemetry.enable;
    })
    // (builtins.listToAttrs (map (s: {
        name = s.name;
        value = builtins.hashString "sha256" s.file;
      })
      secrets))
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

    phpPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = php;
    };

    user = mkOption {
      type = types.str;
      default = "pterodactyl-panel";
      description = "User to run the panel as";
    };

    group = mkOption {
      type = types.str;
      default = if cfg.enableNginx then config.services.nginx.group else "pterodactyl-panel";
      description = "Group to run the panel as";
    };

    enableNginx = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Nginx and PHP-FPM";
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
        default = config.services.pterodactyl.panel.user;
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
        message = "cannot set both services.pterodactyl.panel.app.key and services.pterodactyl.panel.app.keyFile";
      }
      {
        assertion = cfg.database.password == null || cfg.database.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.database.password and services.pterodactyl.panel.database.passwordFile";
      }
      {
        assertion = cfg.redis.password == null || cfg.redis.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.redis.password and services.pterodactyl.panel.redis.passwordFile";
      }
      {
        assertion = cfg.hashids.salt == null || cfg.hashids.saltFile == null;
        message = "cannot set both services.pterodactyl.panel.hashids.salt and services.pterodactyl.panel.hashids.saltFile";
      }
      {
        assertion = cfg.mail.password == null || cfg.mail.passwordFile == null;
        message = "cannot set both services.pterodactyl.panel.mail.password and services.pterodactyl.panel.mail.passwordFile";
      }
    ];

    services.mysql = optionalAttrs cfg.database.createLocally {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [cfg.database.name];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions."${cfg.database.name}.*" = "ALL PRIVILEGES";
        }
      ];
    };

    services.redis.servers."${cfg.redis.name}" = mkIf cfg.redis.createLocally (
      {
        enable = true;
        group = cfg.group;
      }
      // optionalAttrs (cfg.redis.password != null) {requirePass = cfg.redis.password;}
      // optionalAttrs (cfg.redis.passwordFile != null) {requirePassFile = cfg.redis.passwordFile;}
    );

    systemd.tmpfiles.settings."10-pterodactyl-panel" =
      lib.attrsets.genAttrs
      [
        "/var/lib/pterodactyl-panel/storage"
        "/var/lib/pterodactyl-panel/storage/app"
        "/var/lib/pterodactyl-panel/storage/app/public"
        "/var/lib/pterodactyl-panel/storage/app/private"
        "/var/lib/pterodactyl-panel/storage/clockwork"
        "/var/lib/pterodactyl-panel/storage/framework"
        "/var/lib/pterodactyl-panel/storage/framework/cache"
        "/var/lib/pterodactyl-panel/storage/framework/sessions"
        "/var/lib/pterodactyl-panel/storage/framework/views"
        "/var/lib/pterodactyl-panel/storage/logs"
        "/var/lib/pterodactyl-panel/bootstrap"
        "/var/lib/pterodactyl-panel/bootstrap/cache"
      ]
      (n: {
        d = {
          user = cfg.user;
          group = cfg.group;
          mode = "0770";
        };
      })
      // {
        "/var/lib/pterodactyl-panel".d = {
          user = cfg.user;
          group = cfg.group;
          mode = "0750";
        };
      };

    systemd.services.pterodactyl-panel-setup = {
      description = "Pterodactyl Panel setup";
      requiredBy = optional cfg.enableNginx "phpfpm-pterodactyl-panel.service";
      before = optional cfg.enableNginx "phpfpm-pterodactyl-panel.service";
      after = ["mysql.service"];
      restartTriggers = [cfg.package];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.package;
        ReadWritePaths = ["/var/lib/pterodactyl-panel"];
        StateDirectory = "pterodactyl-panel";
      };

      script = ''
        set -eu

        install -D -m 640 -o ${cfg.user} -g ${cfg.group} ${pkgs.writeText "pterodactyl.env" (generators.toKeyValue {
            mkKeyValue = generators.mkKeyValueDefault {
              mkValueString = v:
                if builtins.isString v && strings.hasInfix " " v
                then ''"${v}"''
                else generators.mkValueStringDefault {} v;
            } "=";
          }
          env)} /var/lib/pterodactyl-panel/.env

        ${concatMapStrings (s: ''
            ${pkgs.replace-secret}/bin/replace-secret ${escapeShellArgs [(builtins.hashString "sha256" s.file) s.file "/var/lib/pterodactyl-panel/.env"]}
          '')
          secrets}

        ${php}/bin/php ${cfg.package}/artisan migrate --seed --force
        ${php}/bin/php ${cfg.package}/artisan optimize:clear
      '';
    };

    systemd.services.pteroq = {
      description = "Pterodactyl Queue Worker";
      after = ["pterodactyl-panel-setup.service" "mysql.service" "redis-pterodactyl-panel.service"];
      wants = ["pterodactyl-panel-setup.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        ExecStart = "${php}/bin/php ${cfg.package}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3";
        WorkingDirectory = cfg.package;
        ReadWritePaths = ["/var/lib/pterodactyl-panel"];
        StateDirectory = "pterodactyl-panel";
      };
    };

    systemd.services.pterodactyl-panel-cron = {
      description = "Pterodactyl Panel cron job";
      after = ["pterodactyl-panel-setup.service" "mysql.service" "redis-pterodactyl-panel.service"];
      wants = ["pterodactyl-panel-setup.service"];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.package;
        ReadWritePaths = ["/var/lib/pterodactyl-panel"];
        StateDirectory = "pterodactyl-panel";
        ExecStart = "${php}/bin/php ${cfg.package}/artisan schedule:run";
      };
    };

    systemd.timers.pterodactyl-panel-cron = {
      description = "Pterodactyl Panel cron timer";
      wantedBy = ["timers.target"];
      restartTriggers = [cfg.package];

      timerConfig = {
        OnCalendar = "minutely";
        Persistent = true;
      };
    };

    services.phpfpm.pools.pterodactyl-panel = mkIf cfg.enableNginx {
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

    systemd.services."phpfpm-pterodactyl-panel" = mkIf cfg.enableNginx {
      requires = ["pterodactyl-panel-setup.service"];
    };

    services.nginx = mkIf cfg.enableNginx {
      enable = true;
      recommendedTlsSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      virtualHosts."${builtins.replaceStrings ["https://" "http://"] ["" ""] cfg.app.url}" = {
        root = "${cfg.package}/public";
        extraConfig = ''
          index index.php;
          client_max_body_size 100m;
          client_body_timeout 120s;
          sendfile off;
        '';
        locations = {
          "/" = {
            tryFiles = "$uri $uri/ /index.php?$query_string";
            index = "index.php";
            extraConfig = ''
              sendfile off;
            '';
          };
          "~ \\.php$" = {
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
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/pterodactyl-panel";
      extraGroups = optionals cfg.redis.createLocally ["redis"];
    };
    users.groups.pterodactyl-panel = {};
  };
}
