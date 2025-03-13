{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { ... }: {
    nixosModules.default = { config, lib, pkgs, ... }: let
      cfg = config.steam-console;
    in {
      options.steam-console = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        enableHDR = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        enableVRR = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        enableDecky = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        user = lib.mkOption {
          type = lib.types.str;
        };
        desktopSession = lib.mkOption {
          type = lib.types.str;
          default = "steam-session";
        };
      };

      config = lib.mkIf cfg.enable {
        security.wrappers = {
          # Add gamescope wrapper with renicing (realtime) support
          gamescope = {
            owner = "root";
            group = "root";
            source = "${pkgs.gamescope}/bin/gamescope";
            capabilities = "cap_sys_nice+eip";
          };
          # Add bubblewrap wrapper with setuid
          bwrap = {
            owner = "root";
            group = "root";
            source = "${pkgs.bubblewrap}/bin/bwrap";
            setuid = true;
          };
        };

        # Install steam-session script and use wrappers
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "steam-session" ''
            #!/bin/sh
            if [ -r /home/user/switch-to-desktop ]; then
              rm /home/user/switch-to-desktop
              ${cfg.desktopSession}
            else
              # Use capability wrapper for gamescope
              ${config.security.wrapperDir}/gamescope \
              ${lib.concatStringsSep " " ([
                "--fullscreen"
                "--steam"
                "--rt"
                "--immediate-flips"
              ] ++ lib.optionals cfg.enableHDR [ "--hdr-enabled" "--hdr-itm-enable" ]
                ++ lib.optionals cfg.enableVRR [ "--adaptive-sync" ])} -- \
              ${(pkgs.steam.override {
                buildFHSEnv = pkgs.buildFHSEnv.override {
                  bubblewrap = "${config.security.wrapperDir}/..";
                };
              })}/bin/steam \
              -tenfoot -steamos3 -pipewire-dmabuf \
              > /dev/null 2>&1
            fi
          '')
        ];

        systemd.tmpfiles.rules = [
          # Ensure ~/.local/bin exists and can be accessed
          "d /home/${cfg.user}/.local/bin 0755 ${cfg.user} users -"
          # Create steamos-session-select and symlink to ~/.local/bin
          "L+ /home/${cfg.user}/.local/bin/steamos-session-select - - - - ${
            pkgs.writeTextFile {
              name = "steamos-session-select";
              text = ''
                #!/bin/sh
                touch /home/user/switch-to-desktop
                steam -shutdown
              '';
              executable = true;
            }
          }"
        ];

        # Add ~/.local/bin to user's path
        environment.sessionVariables = {
          PATH = [ "/home/${cfg.user}/.local/bin" ];
        };

        # Make steam-session the default session
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              user = cfg.user;
              command = "steam-session";
            };
          };
        };

        # Optionally install decky-loader service
        lib.mkIf cfg.enableDecky {
          
        };
      };
    };
  };
}
