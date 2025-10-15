{
  fetchFromGitHub,
  php,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:
php.buildComposerProject2 rec {
  pname = "pterodactyl-panel";
  version = "1.11.11";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-Pkko9n0RW4Lu8pc4J58+VXpIpZe+ZRfoCtoTfeDPvI8=";
  };

  composerLock = "${src}/composer.lock";
  vendorHash = "sha256-K6FpYGouMZnZLw7h32OvNbW45QW4qTMIoMqW85vJV+g=";

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-Pv2/0kfOKaAMeioNU1MBdwVEMjDbk+QR8Qs1EwA5bsQ=";
  };

  nativeBuildInputs = [yarnConfigHook yarnBuildHook nodejs];
  NODE_OPTIONS = "--openssl-legacy-provider";
  yarnBuildScript = "build:production";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rT . $out/

    runHook postInstall
  '';
}
