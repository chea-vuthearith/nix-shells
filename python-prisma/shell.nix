{
  pkgs,
  lib,
}: let
  version = "5.17.0";
  engineHash = "393aa359c9ad4a4bb28630fb5613f9c281cde053";

  prismaSystem =
    {
      "x86_64-linux" = "debian-openssl-3.0.x";
      "aarch64-linux" = "linux-arm64-openssl-3.0.x";
      "x86_64-darwin" = "darwin";
      "aarch64-darwin" = "darwin-arm64";
    }.${
      pkgs.stdenv.system
    }
    or (throw "Unsupported system: ${pkgs.stdenv.system}");

  query-engine-file = pkgs.fetchurl {
    url = "https://binaries.prisma.sh/all_commits/${engineHash}/${prismaSystem}/query-engine.gz";
    sha256 = "0z861vvz70g63m0256n2h7llpn93c83p2qpff72n0mqdpvg5gj4v";
  };

  schema-engine-file = pkgs.fetchurl {
    url = "https://binaries.prisma.sh/all_commits/${engineHash}/${prismaSystem}/schema-engine.gz";
    sha256 = "0hcs4s8zb44nnql1n88w1zryqfa3k8x5arfmnqgfm8jdsqzl7bcq";
  };

  libquery-engine-file = pkgs.fetchurl {
    url = "https://binaries.prisma.sh/all_commits/${engineHash}/${prismaSystem}/libquery_engine.so.node.gz";
    sha256 = "1gdiz9x98s02ngsw2sry0i0ga05ynmaq6hmmmf7dpz6pkdrpap8j";
  };

  prisma-fmt-file = pkgs.fetchurl {
    url = "https://binaries.prisma.sh/all_commits/${engineHash}/${prismaSystem}/prisma-fmt.gz";
    sha256 = "0gvrx1gywnrab1jhyvff4xbhgngs3nkl8ivz2sp5dr3z3vdj7gz6";
  };

  prisma-engines-5 = pkgs.stdenv.mkDerivation {
    pname = "prisma-engines";
    inherit version;

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib
      gzip -d < ${query-engine-file} > $out/bin/query-engine
      chmod +x $out/bin/query-engine
      gzip -d < ${schema-engine-file} > $out/bin/schema-engine
      chmod +x $out/bin/schema-engine
      gzip -d < ${libquery-engine-file} > $out/lib/libquery_engine.node
      chmod +x $out/lib/libquery_engine.node
      gzip -d < ${prisma-fmt-file} > $out/bin/prisma-fmt
      chmod +x $out/bin/prisma-fmt
    '';

    meta = with pkgs.lib; {
      description = "Prisma's Database Engines v5.17.0";
      homepage = "https://www.prisma.io/";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
in
  pkgs.mkShell {
    PRISMA_QUERY_ENGINE_BINARY = "${prisma-engines-5}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${prisma-engines-5}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_LIBRARY = "${prisma-engines-5}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY = "${prisma-engines-5}/bin/prisma-fmt";

    shellHook = ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
    '';
  }
