{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pterodactyl.wings;
  mainConfig = {
    debug = cfg.debug;
    app_name = cfg.appName;
    uuid = cfg.uuid;
    token_id =
      if cfg.tokenIdFile != null
      then null
      else cfg.tokenId;
    token =
      if cfg.tokenFile != null
      then null
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
    };
    remote = cfg.remote;
    ignore_panel_config_updates = true;
  };

  wingsConfig = (pkgs.formats.yaml {}).generate "config.yml" (recursiveUpdate (recursiveUpdate mainConfig cfg.extraConfig) (
    if cfg.extraConfigFile != null
    then builtins.fromYAML (builtins.readFile cfg.extraConfigFile)
    else {}
  ));
in {
  options.services.pterodactyl.wings = {
    enable = mkEnableOption "Pterodactyl Wings service";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl.wings;
      defaultText = "pkgs.pterodactyl.wings";
      description = "The Pterodactyl Wings package to use";
    };

    user = mkOption {
      type = types.str;
      default = "pterodactyl-wings";
      description = "User to run wings as";
    };

    group = mkOption {
      type = types.str;
      default = "pterodactyl-wings";
      description = "Group to run wings as";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the wings API and SFTP ports in the firewall";
    };

    rootDir = mkOption {
      type = types.path;
      default = "/var/lib/pterodactyl";
    };

    logDir = mkOption {
      type = types.path;
      default = "/var/log/pterodactyl";
    };

    tmpDir = mkOption {
      type = types.path;
      default = "/var/cache/pterodactyl";
    };

    runDir = mkOption {
      type = types.path;
      default = "/run/wings";
    };

    debug = mkOption {
      type = types.bool;
      default = false;
    };

    appName = mkOption {
      type = types.str;
      default = "Pterodactyl";
    };

    uuid = mkOption {
      type = types.str;
    };

    tokenId = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    tokenIdFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };

    token = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };

    remote = mkOption {
      type = types.str;
    };

    api = {
      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
      };

      port = mkOption {
        type = types.port;
        default = 8080;
      };

      ssl = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };

        certFile = mkOption {
          type = types.nullOr types.path;
          default = null;
        };

        keyFile = mkOption {
          type = types.nullOr types.path;
          default = null;
        };
      };

      uploadLimit = mkOption {
        type = types.int;
        default = 100;
      };

      trustedProxies = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };

    system.sftp = {
      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
      };

      port = mkOption {
        type = types.port;
        default = 2022;
      };
    };

    docker = {
      tmpfsSize = mkOption {
        type = types.int;
        default = 100;
      };

      containerPidLimit = mkOption {
        type = types.int;
        default = 512;
      };

      installerLimits = {
        memory = mkOption {
          type = types.int;
          default = 1024;
        };
        cpu = mkOption {
          type = types.int;
          default = 100;
        };
      };
    };

    extraConfig = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };

    extraConfigFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
  };

  config = mkIf cfg.enable {
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
        assertion = cfg.tokenId != null || cfg.tokenIdFile != null;
        message = "cannot set both services.pterodactyl.wings.tokenId and services.pterodactyl.wings.tokenIdFile";
      }
      {
        assertion = cfg.token != null || cfg.tokenFile != null;
        message = "cannot set both services.pterodactyl.wings.token and services.pterodactyl.wings.tokenFile";
      }
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.api.port cfg.system.sftp.port];

    environment.etc."pterodactyl/config.yml" = {
      source = wingsConfig;
      mode = "0644";
    };

    systemd.services.pterodactyl-wings = {
      description = "Pterodactyl Wings service";
      after = ["network.target" "docker.service"];
      requires = ["docker.service"];
      partOf = ["docker.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/wings --config /etc/pterodactyl/config.yml";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        StateDirectory = "pterodactyl";
        LogsDirectory = "pterodactyl";
        CacheDirectory = "pterodactyl";
        RuntimeDirectory = "wings";
        LoadCredential =
          (optional (cfg.tokenFile != null) "WINGS_TOKEN:${cfg.tokenFile}")
          ++ (optional (cfg.tokenIdFile != null) "WINGS_TOKEN_ID:${cfg.tokenIdFile}");
      };
    };

    systemd.tmpfiles.settings."10-pterodactyl-wings" =
      lib.attrsets.genAttrs
      [
        "${cfg.rootDir}/volumes"
        "${cfg.rootDir}/archives"
        "${cfg.rootDir}/backups"
      ]
      (n: {
        d = {
          user = cfg.user;
          group = cfg.group;
          mode = "0755";
        };
      });

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = ["docker"];
    };
    users.groups.${cfg.group} = {};
  };
}
