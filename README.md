# pterodactyl.nix

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

### Wings

In your `configuration.nix`:

```nix
{
  programs.pterodactyl.wings = {
    enable = true;
    openFirewall = true;
    settings = {
      uuid = "your-node-uuid";
      remote = "https://panel.example.com";
      tokenIdFile = "/path/to/token/id";
      tokenFile = "/path/to/token";
      api.ssl.enable = true;
      api.ssl.certFile = "/path/to/cert";
      api.ssl.keyFile = "/path/to/key";
    };
  };

  virtualisation.docker.enable = true;
}
```
