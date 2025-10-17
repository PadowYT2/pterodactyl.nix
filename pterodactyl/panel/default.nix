{
  fetchFromGitHub,
  php83,
  php83Packages,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:
php83.buildComposerProject2 rec {
  pname = "pterodactyl-panel";
  version = "1.11.11";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-Os8fTkruiUh6+ec5txhVgXPSDC2/LaCtvij7rQuWy0U=";
  };

  composerLock = "${src}/composer.lock";
  vendorHash = "sha256-Y0MHYIaBzBOG6IW+jegcrBbql4pxFPLI56PbO1kh0X0=";

  composerNoDev = false;
  composerNoScripts = false;
  composerNoPlugins = false;

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-Pv2/0kfOKaAMeioNU1MBdwVEMjDbk+QR8Qs1EwA5bsQ=";
  };

  nativeBuildInputs = [yarnConfigHook yarnBuildHook nodejs];
  NODE_OPTIONS = "--openssl-legacy-provider";
  yarnBuildScript = "build:production";
  dontYarnBuild = true;

  postBuild = ''
    yarn --offline ${yarnBuildScript}
    ${php83Packages.composer}/bin/composer dump-autoload --optimize --classmap-authoritative
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rT . $out/

    runHook postInstall
  '';
}
