{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.pterodactyl.wings;
  wingsConfig = pkgs.formats.yaml {}.generate "config.yml" {
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
    remote = cfg.settings.remote;
    allowed_mounts = cfg.settings.allowedMounts;
    allowed_origins = cfg.settings.allowedOrigins;
    ignore_panel_config_updates = cfg.settings.ignorePanelConfigUpdates;
    api = {
      host = cfg.settings.api.host;
      port = cfg.settings.api.port;
      ssl = {
        enabled = cfg.settings.api.ssl.enable;
        cert = cfg.settings.api.ssl.certificateFile;
        key = cfg.settings.api.ssl.keyFile;
      };
      upload_limit = cfg.settings.api.uploadLimit;
      trusted_proxies = cfg.settings.api.trustedProxies;
      allow_cors_private_network = cfg.settings.api.allowCorsPrivateNetwork;
      disable_remote_download = cfg.settings.api.disableRemoteDownload;
    };
    system = {
      root_directory = cfg.rootDir;
      log_directory = cfg.logDir;
      data = "${cfg.rootDir}/volumes";
      archive_directory = "${cfg.rootDir}/archives";
      backup_directory = "${cfg.rootDir}/backups";
      tmp_directory = cfg.tmpDir;
      username = cfg.user;
      timezone = cfg.settings.system.timezone;
      user = {
        rootless = {
          enabled = cfg.settings.system.user.rootless.enable;
          container_uid = cfg.settings.system.user.rootless.containerUid;
          container_gid = cfg.settings.system.user.rootless.containerGid;
        };
        uid = config.users.users.${cfg.user}.uid;
        gid = config.users.groups.${cfg.group}.gid;
      };
      passwd = {
        enabled = cfg.settings.system.passwd.enable;
        directory = "${cfg.runDir}/etc";
      };
      disk_check_interval = cfg.settings.system.diskCheckInterval;
      activity_send_interval = cfg.settings.system.activitySendInterval;
      activity_send_count = cfg.settings.system.activitySendCount;
      check_permissions_on_boot = cfg.settings.system.checkPermissionsOnBoot;
      enable_log_rotate = cfg.settings.system.enableLogRotate;
      websocket_log_count = cfg.settings.system.websocketLogCount;
      sftp = {
        bind_address = cfg.settings.system.sftp.host;
        bind_port = cfg.settings.system.sftp.port;
        read_only = cfg.settings.system.sftp.readOnly;
      };
      crash_detection = {
        enabled = cfg.settings.system.crashDetection.enable;
        detect_clean_exit_as_crash = cfg.settings.system.crashDetection.detectCleanExitAsCrash;
        timeout = cfg.settings.system.crashDetection.timeout;
      };
      backups = {
        write_limit = cfg.settings.system.backups.writeLimit;
        compression_level = cfg.settings.system.backups.compressionLevel;
      };
      transfers = {
        download_limit = cfg.settings.system.transfers.downloadLimit;
      };
      openat_mode = cfg.settings.system.openatMode;
    };
    docker = {
      network = {
        interface = cfg.settings.docker.network.interface;
        dns = cfg.settings.docker.network.dns;
        name = cfg.settings.docker.network.name;
        ispn = cfg.settings.docker.network.ispn;
        driver = cfg.settings.docker.network.driver;
        network_mode = cfg.settings.docker.network.mode;
        is_internal = cfg.settings.docker.network.isInternal;
        enable_icc = cfg.settings.docker.network.enableIcc;
        network_mtu = cfg.settings.docker.network.mtu;
        interfaces = {
          v4 = {
            subnet = cfg.settings.docker.network.interfaces.v4.subnet;
            gateway = cfg.settings.docker.network.interfaces.v4.gateway;
          };
          v6 = {
            subnet = cfg.settings.docker.network.interfaces.v6.subnet;
            gateway = cfg.settings.docker.network.interfaces.v6.gateway;
          };
        };
      };
      domainname = cfg.settings.docker.domainname;
      registries = cfg.settings.docker.registries;
      tmpfs_size = cfg.settings.docker.tmpfsSize;
      container_pid_limit = cfg.settings.docker.containerPidLimit;
      installer_limits = {
        memory = cfg.settings.docker.installerLimits.memory;
        cpu = cfg.settings.docker.installerLimits.cpu;
      };
      overhead = {
        override = cfg.settings.docker.overhead.override;
        default_multiplier = cfg.settings.docker.overhead.defaultMultiplier;
        multipliers = cfg.settings.docker.overhead.multipliers;
      };
      use_performant_inspect = cfg.settings.docker.usePerformantInspect;
      userns_mode = cfg.settings.docker.usernsMode;
      log_config = {
        type = cfg.settings.docker.logConfig.type;
        config = cfg.settings.docker.logConfig.config;
      };
    };
    throttles = {
      enabled = cfg.settings.throttles.enable;
      lines = cfg.settings.throttles.lines;
      line_reset_interval = cfg.settings.throttles.period;
    };
  };
in {
  options.programs.pterodactyl.wings = {
    enable = mkEnableOption "Pterodactyl Wings service";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl-wings;
      defaultText = "pkgs.pterodactyl-wings";
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

      allowedMounts = mkOption {
        type = types.listOf types.str;
        default = [];
      };

      allowedOrigins = mkOption {
        type = types.listOf types.str;
        default = [];
      };

      ignorePanelConfigUpdates = mkOption {
        type = types.bool;
        default = false;
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

          certificateFile = mkOption {
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

        allowCorsPrivateNetwork = mkOption {
          type = types.bool;
          default = false;
        };

        disableRemoteDownload = mkOption {
          type = types.bool;
          default = false;
        };
      };

      system = {
        timezone = mkOption {
          type = types.str;
          default = "UTC";
        };

        user.rootless = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };

          containerUid = mkOption {
            type = types.int;
            default = 0;
          };

          containerGid = mkOption {
            type = types.int;
            default = 0;
          };
        };

        passwd = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
        };

        diskCheckInterval = mkOption {
          type = types.int;
          default = 150;
        };

        activitySendInterval = mkOption {
          type = types.int;
          default = 60;
        };

        activitySendCount = mkOption {
          type = types.int;
          default = 100;
        };

        checkPermissionsOnBoot = mkOption {
          type = types.bool;
          default = true;
        };

        enableLogRotate = mkOption {
          type = types.bool;
          default = true;
        };

        websocketLogCount = mkOption {
          type = types.int;
          default = 150;
        };

        sftp = {
          host = mkOption {
            type = types.str;
            default = "0.0.0.0";
          };

          port = mkOption {
            type = types.port;
            default = 2022;
          };

          readOnly = mkOption {
            type = types.bool;
            default = false;
          };
        };

        crashDetection = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };

          detectCleanExitAsCrash = mkOption {
            type = types.bool;
            default = true;
          };

          timeout = mkOption {
            type = types.int;
            default = 60;
          };
        };

        backups = {
          writeLimit = mkOption {
            type = types.int;
            default = 0;
          };

          compressionLevel = mkOption {
            type = types.enum ["none" "best_speed" "best_compression"];
            default = "best_speed";
          };
        };

        transfers = {
          downloadLimit = mkOption {
            type = types.int;
            default = 0;
          };
        };

        openatMode = mkOption {
          type = types.enum ["auto" "openat" "openat2"];
          default = "auto";
        };
      };

      docker = {
        network = {
          interface = mkOption {
            type = types.str;
            default = "172.18.0.1";
          };

          dns = mkOption {
            type = types.listOf types.str;
            default = ["1.1.1.1" "1.0.0.1"];
          };

          name = mkOption {
            type = types.str;
            default = "pterodactyl_nw";
          };

          ispn = mkOption {
            type = types.bool;
            default = false;
          };

          driver = mkOption {
            type = types.str;
            default = "bridge";
          };

          mode = mkOption {
            type = types.str;
            default = "pterodactyl_nw";
          };

          isInternal = mkOption {
            type = types.bool;
            default = false;
          };

          enableIcc = mkOption {
            type = types.bool;
            default = true;
          };

          mtu = mkOption {
            type = types.int;
            default = 1500;
          };

          interfaces = {
            v4 = {
              subnet = mkOption {
                type = types.str;
                default = "172.18.0.0/16";
              };
              gateway = mkOption {
                type = types.str;
                default = "172.18.0.1";
              };
            };
            v6 = {
              subnet = mkOption {
                type = types.str;
                default = "fdba:17c8:6c94::/64";
              };
              gateway = mkOption {
                type = types.str;
                default = "fdba:17c8:6c94::1011";
              };
            };
          };
        };

        domainname = mkOption {
          type = types.str;
          default = "";
        };

        registries = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              username = mkOption {
                type = types.str;
              };
              password = mkOption {
                type = types.str;
              };
            };
          });
          default = {};
        };

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

        overhead = {
          override = mkOption {
            type = types.bool;
            default = false;
          };
          defaultMultiplier = mkOption {
            type = types.float;
            default = 1.05;
          };
          multipliers = mkOption {
            type = types.attrsOf types.float;
            default = {};
          };
        };

        usePerformantInspect = mkOption {
          type = types.bool;
          default = true;
        };

        usernsMode = mkOption {
          type = types.str;
          default = "";
        };

        logConfig = {
          type = mkOption {
            type = types.str;
            default = "local";
          };
          config = mkOption {
            type = types.attrsOf types.str;
            default = {
              "max-size" = "5m";
              "max-file" = "1";
              "compress" = "false";
              "mode" = "non-blocking";
            };
          };
        };
      };

      throttles = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        lines = mkOption {
          type = types.int;
          default = 2000;
        };
        period = mkOption {
          type = types.int;
          default = 100;
        };
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
