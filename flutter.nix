{
  pkgs ?
    import <nixpkgs> {
      config.android_sdk.accept_license = true;
      config.allowUnfree = true;
    },
}: let
  deviceName = "Default";
  version = "36";
  buildToolsVersion = "35.0.0";
  abi = "x86_64";
  imageType = "google_apis";
  systemImage = "system-images;android-${version};${imageType};${abi}";

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [version];
    abiVersions = [abi];
    systemImageTypes = [imageType];
    includeSystemImages = true;
    includeEmulator = true;
    includeCmake = true;
    cmakeVersions = ["3.22.1"];
    ndkVersions = ["27.0.12077973"];
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
    emulator -avd "${deviceName}"
  '';
in
  pkgs.mkShell rec {
    buildInputs = [
      pkgs.flutter335
      pkgs.jdk21
      androidSdk
      startEmulator
    ];

    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = ANDROID_HOME;
    ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";

    JAVA_HOME = pkgs.jdk21;

    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2";

    shellHook = ''
      export ANDROID_AVD_HOME="$HOME/.config/.android/avd";
      echo "Flutter + Android SDK (API 36) ready"
      # Create AVD if missing
      if ! avdmanager list avd | grep -q "Name: ${deviceName}"; then
        echo "Creating AVD '${deviceName}'"
        echo "no" | avdmanager create avd \
          -n "${deviceName}" \
          -k "${systemImage}" \
          --force
      else
        echo "AVD '${deviceName}' already exists"
      fi
    '';
  }
