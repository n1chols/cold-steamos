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
        # Add capabilities for gamescope realtime and setuid for bubblewrap
        security.wrappers = {
          gamescope = {
            owner = "root";
            group = "root";
            source = "${pkgs.gamescope}/bin/gamescope";
            capabilities = "cap_sys_nice+eip";
          };
          bwrap = {
            owner = "root";
            group = "root";
            source = "${pkgs.bubblewrap}/bin/bwrap";
            setuid = true;
          };
        };

        # Install gamescope, steam with bwrap override, and steam-session script
        environment.systemPackages = [
          pkgs.gamescope
          (pkgs.steam.override {
            buildFHSEnv = pkgs.buildFHSEnv.override {
              bubblewrap = "${config.security.wrapperDir}/..";
            };
          })
          (pkgs.writeShellScriptBin "steam-session" ''
            #!/bin/sh
            exec ${config.security.wrapperDir}/gamescope -f -e --rt --immediate-flips -- \
            ${(pkgs.steam.override { buildFHSEnv = pkgs.buildFHSEnv.override { bubblewrap = "${config.security.wrapperDir}/.."; }; })}/bin/steam -tenfoot -steamos3 -pipewire-dmabuf
          '')
        ];

        # Symlink steamos-session-select to the user's home
        systemd.tmpfiles.rules = [
          "d /home/${cfg.user}/.local/bin 0755 ${cfg.user} ${cfg.user} -"
          "L /home/${cfg.user}/.local/bin/steamos-session-select - - - - ${
            pkgs.writeTextFile {
              name = "steamos-session-select";
              text = ''
                #!/bin/sh
                steam -shutdown
                ${cfg.desktopSession}
              '';
              executable = true;
            }
          }"
        ];

        # Launch steam-session on startup
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              user = cfg.user;
              command = "steam-session";
            };
          };
        };
      };
    };
  };
}
