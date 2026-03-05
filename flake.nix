{
  description = "Nix development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.android_sdk.accept_license = true;
          config.allowUnfree = true;
        };
      in {
        flutter = import ./flutter/shell.nix {inherit pkgs;};
        python-prisma = import ./python-prisma/shell.nix {inherit pkgs;};
      }
    );
  };
}
