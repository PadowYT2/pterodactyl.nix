{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "wings";
  version = "1.11.13";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-UpYUHWM2J8nH+srdKSpFQEaPx2Rj2+YdphV8jJXcoBU=";
  };

  vendorHash = "sha256-eWfQE9cQ7zIkITWwnVu9Sf9vVFjkQih/ZW77d6p/Iw0=";
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/pterodactyl/wings/system.Version=${version}"
  ];

  meta = {
    description = "The server control plane for Pterodactyl Panel. Written from the ground-up with security, speed, and stability in mind.";
    homepage = "https://pterodactyl.io";
    changelog = "https://github.com/pterodactyl/wings/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
