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

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
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
  
          # Install steam-session script with wrappers
          environment.systemPackages = [
            (pkgs.writeShellScriptBin "steam-session" ''
              #!/bin/sh
              if [ -r $XDG_RUNTIME_DIR/switch-to-desktop ]; then
                rm $XDG_RUNTIME_DIR/switch-to-desktop
                ${cfg.desktopSession}
                steam -silent -skipinitialbootstrap
              else
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
                -tenfoot -steamos3 -pipewire-dmabuf #-forcepackagedownload \
                > /dev/null 2>&1
              fi
            '')
          ];
  
          systemd.tmpfiles.rules = [
            # Ensure ~/.local/bin exists and can be accessed
            "d /home/${cfg.user}/.local/bin 0755 ${cfg.user} users -"
            # Create steamos-session-select script
            "f /home/${cfg.user}/.local/bin/steamos-session-select 0755 ${cfg.user} users - ${''
              #!/bin/sh
              touch $XDG_RUNTIME_DIR/switch-to-desktop
              steam -shutdown
            ''}"
            # Ensure ~/.local/share/applications exists and can be accessed
            "d /home/${cfg.user}/.local/share/applications 0755 ${cfg.user} users -"
            # Create 'Return to Gaming Mode' shortcut
            "f /home/${cfg.user}/.local/share/applications/gaming-mode.desktop 0644 ${cfg.user} users - ${''
              [Desktop Entry]
              Name=Return to Gaming Mode
              Exec=loginctl terminate-session $XDG_SESSION_ID
              Type=Application
            ''}"
            # Symlink 'Return to Gaming Mode' shortcut to desktop
            "L+ /home/${cfg.user}/Desktop/gaming-mode.desktop - - - - /home/${cfg.user}/.local/share/applications/gaming-mode.desktop"
          ];
  
          # Add ~/.local/bin to path
          environment.sessionVariables = {
            PATH = [ "/home/${cfg.user}/.local/bin" ];
          };

          # Add udev rule needed for gamepad emulation
          #services.udev.extraRules = ''
          #  KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
          #'';
  
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
        }
        (lib.mkIf cfg.enableDecky {
          # Create decky user and group
          users = {
            users.decky = {
              group = "decky";
              isSystemUser = true;
            };
            groups.decky = {};
          };

          systemd.tmpfiles.rules = [
            # Enable CEF remote debugging
            "f /home/${cfg.user}/.local/share/Steam/.cef-enable-remote-debugging 0644 ${cfg.user} users -"
            # Ensure /var/lib/decky exists and can be accessed
            "d /var/lib/decky 0755 decky decky -"
          ];

          # Create decky-loader service
          systemd.services.decky-loader = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            environment = {
              UNPRIVILEGED_USER = "decky";
              UNPRIVILEGED_PATH = "/var/lib/decky";
              PLUGIN_PATH = "/var/lib/decky/plugins";
            };
            serviceConfig = {
              ExecStart = "${pkgs.callPackage ./pkgs/decky-loader {}}/bin/decky-loader";
              KillMode = "process";
              TimeoutStopSec = 15;
            };
          };
        })
      ]);
    };
  };
}
