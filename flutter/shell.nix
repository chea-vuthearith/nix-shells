{
  pkgs,
  lib,
}: let
  deviceName = "Default";
  version = "36";
  buildToolsVersion = "35.0.0";
  abi = "x86_64";
  imageType = "google_apis";
  systemImage = "system-images;android-${version};${imageType};${abi}";
  advConfigOptions = {
    "hw.gpu.enabled" = "yes";
    "hw.gpu.mode" = "host";
  };
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [version "35"];
    abiVersions = [abi];
    systemImageTypes = [imageType];
    includeSystemImages = true;
    includeEmulator = true;
    includeCmake = true;
    cmakeVersions = ["3.22.1"];
    ndkVersions = ["28.2.13676358"];
    buildToolsVersions = [buildToolsVersion];
    includeNDK = true;
    extraLicenses = [
      "android-googletv-license"
      "android-googlexr-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "microxr-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
  startEmulator = pkgs.writeShellScriptBin "start-emulator" ''
    emulator -avd "${deviceName}" -gpu host -no-snapshot
  '';
in
  pkgs.mkShell rec {
    buildInputs = [
      androidSdk
      startEmulator
      pkgs.flutter341
      pkgs.jdk21
      pkgs.libGL
      pkgs.mesa
      pkgs.libX11
      pkgs.vulkan-loader
      pkgs.vulkan-tools
      pkgs.vulkan-validation-layers
    ];

    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = ANDROID_HOME;
    ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";

    JAVA_HOME = pkgs.jdk21;

    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2";
    QT_QPA_PLATFORM = "xcb";

    shellHook = ''
      export ANDROID_AVD_HOME="$HOME/.config/.android/avd";
      export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

      if ! avdmanager list avd | grep -q "Name: ${deviceName}"; then
        echo "Creating AVD '${deviceName}'"
        echo "no" | avdmanager create avd \
          -n "${deviceName}" \
          -k "${systemImage}" \
          --force

        CONFIG_INI="$ANDROID_AVD_HOME/${deviceName}.avd/config.ini"
        ${builtins.concatStringsSep "\n" (
        lib.mapAttrsToList (configKey: configValue: ''
          sed -i "/^${configKey}[[:space:]]*=/d" "$CONFIG_INI"
          echo "${configKey} = ${configValue}" >> "$CONFIG_INI"
        '')
        advConfigOptions
      )}
      fi


    '';
  }
