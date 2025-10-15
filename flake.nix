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
      nixosModules.default = import ./module.nix;
      overlays.default = import ./overlays.nix;
    }
    // (inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          inputs.gomod2nix.overlays.default
        ];
      };
    in {
      packages = {
        pterodactyl = pkgs.pterodactyl;
      };
    }));
}
