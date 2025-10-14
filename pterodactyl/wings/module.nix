{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.pterodactyl.wings;
  mainConfig = {
    debug = cfg.settings.debug;
    app_name = cfg.settings.appName;
    uuid = cfg.settings.uuid;
    token_id =
      if cfg.settings.tokenIdFile != null
      then null
      else cfg.settings.tokenId;
    token =
      if cfg.settings.tokenFile != null
      then null
      else cfg.settings.token;
    api = {
      host = cfg.settings.api.host;
      port = cfg.settings.api.port;
      ssl = {
        enabled = cfg.settings.api.ssl.enable;
        cert = cfg.settings.api.ssl.certFile;
        key = cfg.settings.api.ssl.keyFile;
      };
      upload_limit = cfg.settings.api.uploadLimit;
      trusted_proxies = cfg.settings.api.trustedProxies;
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
        bind_address = cfg.settings.system.sftp.host;
        bind_port = cfg.settings.system.sftp.port;
      };
      docker = {
        tmpfs_size = cfg.settings.docker.tmpfsSize;
        container_pid_limit = cfg.settings.docker.containerPidLimit;
        installer_limits = {
          memory = cfg.settings.docker.installerLimits.memory;
          cpu = cfg.settings.docker.installerLimits.cpu;
        };
      };
      passwd.directory = "${cfg.runDir}/etc";
    };
    remote = cfg.settings.remote;
    ignore_panel_config_updates = true;
  };

  wingsConfig = pkgs.formats.yaml {}.generate "config.yml" (recursiveUpdate (recursiveUpdate mainConfig cfg.settings.extraConfig) (
    if cfg.settings.extraConfigFile != null
    then builtins.fromYAML (builtins.readFile cfg.settings.extraConfigFile)
    else {}
  ));
in {
  options.programs.pterodactyl.wings = {
    enable = mkEnableOption "Pterodactyl Wings service";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl.wings;
      defaultText = "pkgs.pterodactyl.wings";
      description = "The Pterodactyl Wings package to use";
    };

    user = mkOption {
      type = types.str;
      default = "pterodactyl";
      description = "User to run wings as";
    };

    group = mkOption {
      type = types.str;
      default = "pterodactyl";
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

    settings = {
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
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message = "programs.pterodactyl.wings requires virtualisation.docker to be enabled";
      }
      {
        assertion = cfg.settings.uuid != "";
        message = "programs.pterodactyl.wings.settings.uuid must be set";
      }
      {
        assertion = cfg.settings.remote != "";
        message = "programs.pterodactyl.wings.settings.remote must be set";
      }
      {
        assertion = (cfg.settings.tokenId != null && cfg.settings.token != null) || (cfg.settings.tokenIdFile != null && cfg.settings.tokenFile != null);
        message = "either (tokenId and token) or (tokenIdFile and tokenFile) must be set in programs.pterodactyl.wings.settings";
      }
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.settings.api.port cfg.settings.system.sftp.port];

    environment.etc."pterodactyl/config.yml" = {
      source = wingsConfig;
      owner = cfg.user;
      group = cfg.group;
      mode = "0600";
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
      };

      serviceConfig.LoadCredential =
        (optional (cfg.settings.tokenFile != null) "WINGS_TOKEN:${cfg.settings.tokenFile}")
        ++ (optional (cfg.settings.tokenIdFile != null) "WINGS_TOKEN_ID:${cfg.settings.tokenIdFile}");
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.rootDir}/volumes 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.rootDir}/archives 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.rootDir}/backups 0755 ${cfg.user} ${cfg.group} -"
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = ["docker"];
    };
    users.groups.${cfg.group} = {};
  };
}
