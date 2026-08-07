{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "pterodactyl-wings";
  version = "1.13.2";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "wings";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rvt5eqpHDxARivgYfGqM/BC3wxvVtx/b3PJVbJh+tac=";
  };

  vendorHash = "sha256-BtATik0egFk73SNhawbGnbuzjoZioGFWeA4gZOaofTI=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/pterodactyl/wings/system.Version=${finalAttrs.version}"
  ];

  meta = {
    description = "Server control plane for Pterodactyl Panel";
    homepage = "https://pterodactyl.io";
    changelog = "https://github.com/pterodactyl/wings/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "wings";
    platforms = lib.platforms.linux;
  };
})
