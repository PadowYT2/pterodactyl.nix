{
  stdenvNoCC,
  fetchFromGitHub,
  php83,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  dataDir ? "/var/lib/pterodactyl-panel",
}:
stdenvNoCC.mkDerivation rec {
  pname = "pterodactyl-panel";
  version = "1.11.11";

  src = fetchFromGitHub {
    owner = "pterodactyl";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-Os8fTkruiUh6+ec5txhVgXPSDC2/LaCtvij7rQuWy0U=";
  };

  buildInputs = [php83];
  nativeBuildInputs = [
    nodejs
    yarnConfigHook
    yarnBuildHook
    php83.composerHooks2.composerInstallHook
  ];

  composerVendor = php83.mkComposerVendor {
    inherit pname src version;
    composerNoDev = true;
    composerNoPlugins = true;
    composerNoScripts = true;
    composerStrictValidation = true;
    strictDeps = true;
    vendorHash = "sha256-B9BAi1E9T2rk2AifAWfAk0Lp87fUxHore8Woh368H6I=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-Pv2/0kfOKaAMeioNU1MBdwVEMjDbk+QR8Qs1EwA5bsQ=";
  };

  env.NODE_OPTIONS = "--openssl-legacy-provider";
  yarnBuildScript = "build:production";
  dontYarnBuild = true;

  preInstall = ''
    yarn --offline build:production
  '';

  postInstall = ''
    chmod -R u+w $out/share
    mv $out/share/php/pterodactyl-panel/* $out/
    rm -R $out/share $out/storage $out/bootstrap/cache $out/node_modules
    ln -s ${dataDir}/storage $out/storage
    ln -s ${dataDir}/bootstrap/cache $out/bootstrap/cache
    ln -s ${dataDir}/.env $out/.env
  '';
}
