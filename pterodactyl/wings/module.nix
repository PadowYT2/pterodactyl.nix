{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.pterodactyl.wings;

  mainConfig = {
    debug = cfg.debug;
    app_name = cfg.appName;
    uuid = cfg.uuid;
    token_id =
      if cfg.tokenIdFile != null
      then "@TOKEN_ID@"
      else cfg.tokenId;
    token =
      if cfg.tokenFile != null
      then "@TOKEN@"
      else cfg.token;
    api = {
      host = cfg.api.host;
      port = cfg.api.port;
      ssl = {
        enabled = cfg.api.ssl.enable;
        cert = cfg.api.ssl.certFile;
        key = cfg.api.ssl.keyFile;
      };
      upload_limit = cfg.api.uploadLimit;
      trusted_proxies = cfg.api.trustedProxies;
    };
    system = {
      root_directory = cfg.rootDir;
      log_directory = cfg.logDir;
      data = "${cfg.rootDir}/volumes";
      archive_directory = "${cfg.rootDir}/archives";
      backup_directory = "${cfg.rootDir}/backups";
      tmp_directory = cfg.tmpDir;
      username = cfg.user;
      user = {
        uid = config.users.users.${cfg.user}.uid;
        gid = config.users.groups.${cfg.group}.gid;
      };
      sftp = {
        bind_address = cfg.system.sftp.host;
        bind_port = cfg.system.sftp.port;
      };
      docker = {
        tmpfs_size = cfg.docker.tmpfsSize;
        container_pid_limit = cfg.docker.containerPidLimit;
        installer_limits = {
          memory = cfg.docker.installerLimits.memory;
          cpu = cfg.docker.installerLimits.cpu;
        };
      };
      passwd.directory = "${cfg.runDir}/etc";
      use_openat2 = false;
    };
    remote = cfg.remote;
    ignore_panel_config_updates = true;
  };

  wingsConfig = (pkgs.formats.yaml {}).generate "config.yml" (lib.recursiveUpdate mainConfig cfg.extraConfig);
in {
  options.services.pterodactyl.wings = {
    enable = lib.mkEnableOption "Pterodactyl Wings service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pterodactyl.wings;
      defaultText = "pkgs.pterodactyl.wings";
      description = "The Pterodactyl Wings package to use";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pterodactyl-wings";
      description = "User to run wings as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "pterodactyl-wings";
      description = "Group to run wings as";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the wings API and SFTP ports in the firewall";
    };

    rootDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pterodactyl";
    };

    logDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/log/pterodactyl";
    };

    tmpDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/cache/pterodactyl";
    };

    runDir = lib.mkOption {
      type = lib.types.path;
      default = "/run/wings";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    appName = lib.mkOption {
      type = lib.types.str;
      default = "Pterodactyl";
    };

    uuid = lib.mkOption {
      type = lib.types.str;
    };

    tokenId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    tokenIdFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    token = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    remote = lib.mkOption {
      type = lib.types.str;
    };

    api = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };

      ssl = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        certFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
        };

        keyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
        };
      };

      uploadLimit = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };

      trustedProxies = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };

    system.sftp = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2022;
      };
    };

    docker = {
      tmpfsSize = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };

      containerPidLimit = lib.mkOption {
        type = lib.types.int;
        default = 512;
      };

      installerLimits = {
        memory = lib.mkOption {
          type = lib.types.int;
          default = 1024;
        };
        cpu = lib.mkOption {
          type = lib.types.int;
          default = 100;
        };
      };
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message = "services.pterodactyl.wings requires virtualisation.docker to be enabled";
      }
      {
        assertion = cfg.uuid != "";
        message = "services.pterodactyl.wings.uuid must be set";
      }
      {
        assertion = cfg.remote != "";
        message = "services.pterodactyl.wings.remote must be set";
      }
      {
        assertion = cfg.tokenId == null || cfg.tokenIdFile == null;
        message = "cannot set both services.pterodactyl.wings.tokenId and services.pterodactyl.wings.tokenIdFile";
      }
      {
        assertion = cfg.tokenId != null || cfg.tokenIdFile != null;
        message = "must set either services.pterodactyl.wings.tokenId or services.pterodactyl.wings.tokenIdFile";
      }
      {
        assertion = cfg.token == null || cfg.tokenFile == null;
        message = "cannot set both services.pterodactyl.wings.token and services.pterodactyl.wings.tokenFile";
      }
      {
        assertion = cfg.token != null || cfg.tokenFile != null;
        message = "must set either services.pterodactyl.wings.token or services.pterodactyl.wings.tokenFile";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.api.port cfg.system.sftp.port];

    systemd.tmpfiles.settings."10-pterodactyl-wings" =
      lib.attrsets.genAttrs
      [
        "${cfg.rootDir}/volumes"
        "${cfg.rootDir}/volumes/.sftp"
        "${cfg.rootDir}/archives"
        "${cfg.rootDir}/backups"
      ]
      (n: {
        d = {
          user = cfg.user;
          group = cfg.group;
          mode = "0755";
        };
      })
      // {
        "${cfg.rootDir}".d = {
          user = cfg.user;
          group = cfg.group;
          mode = "0750";
        };
        "${cfg.rootDir}/wings.db".z = {
          user = cfg.user;
          group = cfg.group;
          mode = "0644";
        };
        "${cfg.rootDir}/states.json".z = {
          user = cfg.user;
          group = cfg.group;
          mode = "0644";
        };
      };

    systemd.services.pterodactyl-wings-setup = {
      description = "Pterodactyl Wings setup";
      before = ["pterodactyl-wings.service"];
      requiredBy = ["pterodactyl-wings.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "pterodactyl";
      };

      script = ''
        set -eu

        install -D -m 640 -o ${cfg.user} -g ${cfg.group} ${wingsConfig} /var/lib/pterodactyl/config.yml

        ${lib.optionalString (cfg.tokenIdFile != null) ''
          ${pkgs.replace-secret}/bin/replace-secret '@TOKEN_ID@' ${lib.escapeShellArg cfg.tokenIdFile} /var/lib/pterodactyl/config.yml
        ''}

        ${lib.optionalString (cfg.tokenFile != null) ''
          ${pkgs.replace-secret}/bin/replace-secret '@TOKEN@' ${lib.escapeShellArg cfg.tokenFile} /var/lib/pterodactyl/config.yml
        ''}
      '';
    };

    systemd.services.pterodactyl-wings = {
      description = "Pterodactyl Wings service";
      after = ["network-online.target" "docker.service" "pterodactyl-wings-setup.service"];
      wants = ["network-online.target"];
      requires = ["docker.service" "pterodactyl-wings-setup.service"];
      partOf = ["docker.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/wings --config /var/lib/pterodactyl/config.yml";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        StateDirectory = "pterodactyl";
        LogsDirectory = "pterodactyl";
        CacheDirectory = "pterodactyl";
        RuntimeDirectory = "wings";
        ReadWritePaths = [
          cfg.rootDir
          cfg.logDir
          cfg.tmpDir
          cfg.runDir
        ];
        AmbientCapabilities = "CAP_CHOWN";
      };
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.rootDir;
      extraGroups = ["docker"];
    };

    users.groups.${cfg.group} = {};
  };
}
