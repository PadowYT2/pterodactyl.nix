{
  description = "A free, open-source game server management panel built with PHP, React, and Go. Designed with security in mind, Pterodactyl runs all game servers in isolated Docker containers while exposing a beautiful and intuitive UI to end users.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs:
    {
      nixosModules.default = {
        imports = [
          ./pterodactyl/panel/module.nix
          ./pterodactyl/wings/module.nix
        ];
      };

      overlays.default = final: prev: {
        pterodactyl = {
          panel = prev.callPackage ./pterodactyl/panel/default.nix {};
          wings = prev.callPackage ./pterodactyl/wings/default.nix {};
        };
      };
    }
    // (inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      packages = {
        pterodactyl = pkgs.pterodactyl;
      };
    }));
}
