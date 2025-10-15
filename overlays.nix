final: prev: {
  pterodactyl = {
    panel = prev.callPackage ./pterodactyl/panel/default.nix {};
    wings = prev.callPackage ./pterodactyl/wings/default.nix {};
  };
}
