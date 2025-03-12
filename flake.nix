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
        environment.systemPackages = [
          pkgs.gamescope
          pkgs.steam
          (pkgs.writeShellScriptBin "steam-session" ''
            #!/bin/sh
            exec ${config.security.wrapperDir}/gamescope -f -e -- ${pkgs.steam}/bin/steam -tenfoot -steamos3 > /dev/null 2>&1
          '')
        ];
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
