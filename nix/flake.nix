{
  description = "Nix flake for sfsnowsightextensions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        # Does not work yet
        # "x86_64-darwin"
        # "aarch64-darwin"
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages =
          let
            authString = ''
              Import-Module ${self'.packages.default}/lib/SnowflakePS.psd1
              \$password = ConvertTo-SecureString "$SNOWFLAKE_PASSWORD" -AsPlainText -Force
              \$app = Connect-SFApp -Account "$SNOWFLAKE_ACCOUNT" -UserName "$SNOWFLAKE_USER" -Password \$password
            '';
          in
          {
            default = pkgs.buildDotnetModule {
              name = "SnowflakePS";
              src = ./..;
              projectFile = ../SnowflakePS.csproj;
              # Run nix build .#default.fetch-deps to calculate
              # then edit the result to replace paths to flake with local path
              # nugetDeps = ./test-deps-Pa9mcP.nix;
              nugetDeps = ./SnowflakePS-deps-MsWTzc.nix;
              postInstall =
                ''
                  ${pkgs.lib.getExe pkgs.rsync} -av \
                    --exclude='flake.nix' \
                    --exclude='flake.lock' \
                    --exclude='.envrc' \
                    --exclude='result' \
                    . $out/lib/
                '';
            };
            _sampleAuthScript = pkgs.writeText "sfsnowsightextensions-auth.ps1"
              ''
                Import-Module ${self'.packages.default}/lib/SnowflakePS.psd1
                $password = ConvertTo-SecureString $env:SNOWFLAKE_PASSWORD -AsPlainText -Force
                $app = Connect-SFApp -Account $env:SNOWFLAKE_ACCOUNT -UserName $env:SNOWFLAKE_USER -Password $password
              '';
            sfsnowsightextensions-env = pkgs.writeShellApplication {
              name = "sfsnowsightextensions";
              text =
                ''
                  ${pkgs.lib.getExe pkgs.powershell} -NoExit ${self'.packages._sampleAuthScript}
                '';
            };

            sample-create-worksheet = pkgs.writeShellApplication
              {
                name = "sample-create-worksheet";
                text = ''
                  cat <<EOF | ${pkgs.lib.getExe pkgs.powershell} -NoExit -Command -
                  ${authString}
                  \$worksheet = Get-Content './sampleWorksheet.json' | ConvertFrom-JSON
                  New-SFWorksheet -AuthContext \$app -Worksheet \$worksheet -ActionIfExists Overwrite
                  EOF
                  echo "Worksheet created!"
                '';
              };
          };
        apps =
          let mkApp = program: { type = "app"; inherit program; }; in
          {
            sfsnowsightextensions-launch = mkApp "${pkgs.lib.getExe self'.packages.sfsnowsightextensions-env}";
            sample-create-worksheet = mkApp "${pkgs.lib.getExe self'.packages.create-worksheet}";
          };
        devshells.default = {
          env = [ ];
          commands = [
            {
              name = "sfsnowsightextensions-launch";
              help = "Launches powershell session with the sfsnowsightextensions imported";
              command = ''
                nix run .#sfsnowsightextensions-launch
              '';
            }
            {
              name = "sample-create-worksheet";
              help = "Authenticates in Snowflake and creates a sample worksheet";
              command = ''
                nix run .#sample-create-worksheet
              '';
            }
          ];
          packages = [
            pkgs.powershell
          ];
        };

      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
