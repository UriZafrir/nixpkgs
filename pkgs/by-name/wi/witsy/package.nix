{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
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

  npmDepsHash = "sha256-Tqh63RC9Q64KdHFT7DW3IJWviM/pRVLLYqycHskheGQ=";

  nativeBuildInputs = [
    nodejs
  ];

  forceGitDeps = true;

  makeCacheWritable = true;

  npmFlags = [ "--ignore-scripts" ];

  postPatch = ''
    # Remove the problematic Git dependency @vue/test-utils which has install scripts requiring rollup
    # This is a dev dependency used for testing and not needed for the build
    ${jq}/bin/jq 'del(.devDependencies."@vue/test-utils")' package.json > package.json.tmp
    mv package.json.tmp package.json
    ${jq}/bin/jq '
      del(.devDependencies."@vue/test-utils") |
      walk(
        if type == "object" and has("packages") then
          .packages |= with_entries(select(.key | contains("@vue/test-utils") | not))
        else .
        end
      )
    ' package-lock.json > package-lock.json.tmp
    mv package-lock.json.tmp package-lock.json

    # Set electronDist in forge.config.ts to use Nix electron
    sed -i 's|const config: ForgeConfig = {|const config: ForgeConfig = {\n  electronDist: process.env.electronDist,|' forge.config.ts
  '';

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  env.electronDist = "${electron.dist}";

  configurePhase = ''
    export npm_config_offline="false"
    export npm_config_ignore_scripts="true"
  '';

  buildInputs = [ electron ];

  npmBuildScript = "package";

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
    cp -r out/Witsy-linux-x64/resources/app $out/share/witsy/

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