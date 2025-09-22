{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  prefetch-npm-deps,
  electron,
  makeDesktopItem,
  makeWrapper,
  nodejs,
  nodePackages,
  jq,
}:

buildNpmPackage rec {
  pname = "witsy";
  version = "2.14.0";

  src = fetchFromGitHub {
    owner = "nbonamy";
    repo = "witsy";
    tag = "v${version}";
    hash = "sha256-YW07wBx5Ybf+87gTY6QhxuK772kNo64qqED9RCPa/uw=";
  };

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    inherit src;
    forceGitDeps = true;
    hash = "sha256-6l8Tgd9wxtnTgjNktBIO/b9lDJhi72vMePdwLGctlSM=";
  };

  nativeBuildInputs = [
    prefetch-npm-deps
    nodejs
  ];

  makeCacheWritable = true;

  npmFlags = [ "--ignore-scripts" ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  env.ELECTRON_VERSION = electron.version;
  env.NODE_OPTIONS = "--dns-result-order=ipv4first";
  env.prefetchNpmDeps = "${prefetch-npm-deps}/bin/prefetch-npm-deps";

  configurePhase = ''
    export npm_config_offline="false"
    export npm_config_ignore_scripts="true"
  '';

  preConfigure = ''
    export prefetchNpmDeps="${prefetch-npm-deps}/bin/prefetch-npm-deps"
  '';

  postBuild = ''
    # Copy Electron distribution and make it writable (standard for electron-builder)
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    # Build with electron-builder in directory mode
    npm exec electron-builder -- \
      --dir \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version}
  '';

  buildInputs = [ electron ];

  npmConfigCache = "/tmp/npm-cache";

  desktopItem = makeDesktopItem {
    name = "witsy";
    exec = "witsy %U";
    icon = "witsy";
    desktopName = "Witsy";
    genericName = "LLM Chat App";
    comment = "Interact with LLMs";
    categories = [ "Utility" ];
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/witsy $out/share/applications

    # Copy the built app
    cp -r dist/linux-unpacked/resources/app $out/share/witsy/

    # Wrap electron
    makeWrapper ${electron}/bin/electron $out/bin/witsy \
      --add-flags $out/share/witsy \
      --set ELECTRON_IS_PACKAGED 1

    # Desktop file
    cp ${desktopItem}/share/applications/* $out/share/applications/

    # TODO: add icon if available

    runHook postInstall
  '';

  meta = {
    description = "An app to interact with LLMs";
    homepage = "https://github.com/nbonamy/witsy";
    license = lib.licenses.mit;
    maintainers = [ ]; # TODO: add maintainer
    platforms = electron.meta.platforms;
    mainProgram = "witsy";
  };
}