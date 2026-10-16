# pterodactyl.nix

> [!IMPORTANT]
> I will not be updating maintaining this project when v1 will be out of support. Neither an updated version for v2 will come. See https://gist.github.com/PadowYT2/aab3e0e839f8294d46b12670122a4be1.
>
> If you would like to take over the project, please feel free to DM me or just fork.

A flake made for [Pterodactyl](https://pterodactyl.io): A free, open-source game server management panel built with PHP, React, and Go. Designed with security in mind, Pterodactyl runs all game servers in isolated Docker containers while exposing a beautiful and intuitive UI to end users.

## Usage

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pterodactyl.url = "github:PadowYT2/pterodactyl.nix";
  };

  outputs = {
    self,
    nixpkgs,
    pterodactyl,
  }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        pterodactyl.nixosModules.default
        {nixpkgs.overlays = [pterodactyl.overlays.default];}
        ./configuration.nix
      ];
    };
  };
}
```

### Panel

In your `configuration.nix`:

```nix
{
  services.pterodactyl.panel = {
    enable = true;
    app = {
      url = "https://panel.example.com";
      # echo "base64:$(openssl rand -base64 32)"
      keyFile = "/path/to/app.key";
    };
    # you can use *.password = "password_here";
    database.passwordFile = "/path/to/db/password";
    redis.passwordFile = "/path/to/redis/password";
    hashids.saltFile = "/path/to/hashids/salt";
    mail.passwordFile = "/path/to/mail/password";
  };
}
```

#### Caddy with FrankenPHP

Using Caddy with FrankenPHP is much performant and better than Nginx and PHP-FPM.

Here is an example to put in your `configuration.nix`:

```nix
{
  services.caddy = {
    enable = true;
    package = pkgs.frankenphp.override {
      php = config.services.pterodactyl.panel.phpPackage;
    };
    virtualHosts = {
      "panel.example.com".extraConfig = ''
        root * ${config.services.pterodactyl.panel.package}/public
        php_server
      '';
    };
  };

  services.pterodactyl.panel = {
    enable = true;
    enableNginx = false;
    user = "caddy";
    group = "caddy";
    database.user = "caddy";
    app.url = "https://panel.example.com";
  };

  users.users.caddy.extraGroups = ["redis"];
}
```

### Wings

In your `configuration.nix`:

```nix
{
  services.pterodactyl.wings = {
    enable = true;
    openFirewall = true;

    secrets = {
      tokenIdFile = "/path/to/token/id";
      tokenFile = "/path/to/token";
    };

    settings = {
      uuid = "your-node-uuid";
      remote = "https://panel.example.com";
      api.ssl = {
        enable = true;
        cert = "/path/to/cert.pem";
        key = "/path/to/key.pem";
      };
    };
  };

  virtualisation.docker.enable = true;
}
```
