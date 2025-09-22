let
  pkgs = import ./. {};
  witsy-src = pkgs.fetchFromGitHub {
    owner = "nbonamy";
    repo = "witsy";
    tag = "v2.14.0";
    hash = "sha256-YW07wBx5Ybf+87gTY6QhxuK772kNo64qqED9RCPa/uw=";
  };
in
pkgs.fetchNpmDeps {
  name = "witsy-2.14.0-npm-deps";
  src = witsy-src;
  forceGitDeps = true;
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # dummy
}