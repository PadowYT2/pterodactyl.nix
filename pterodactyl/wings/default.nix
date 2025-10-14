{
  buildGoApplication,
  fetchFromGitHub,
}:
buildGoApplication rec {
  pname = "wings";
  version = "1.11.13";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-UpYUHWM2J8nH+srdKSpFQEaPx2Rj2+YdphV8jJXcoBU=";
  };

  modules = ./gomod2nix.toml;

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/pterodactyl/wings/system.Version=${version}"
  ];
}
