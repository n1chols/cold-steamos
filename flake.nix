{
  outputs = { self, nixpkgs }: {
    nixosModules.default = { config, lib, pkgs, ... }: let
      cfg = config.steam-console;
    in {
      options.steam-console = {
        enable = lib.mkEnableOption "";
        enableHDR = lib.mkEnableOption "";
        enableVRR = lib.mkEnableOption "";
        enableDecky = lib.mkEnableOption "";
        enablePlymouth = lib.mkEnableOption "";
        desktopSession = lib.mkOption {
          type = lib.types.str;
          default = "steam-session";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "steamuser";
        };
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          # Enable OpenGL w/ 32-bit support
          hardware.graphics = {
            enable = true;
            enable32Bit = true;
          };

          security.wrappers = {
            # Add gamescope wrapper w/ renicing
            gamescope = {
              owner = "root";
              group = "root";
              source = "${pkgs.gamescope}/bin/gamescope";
              capabilities = "cap_sys_nice+eip";
            };
            # Add bubblewrap wrapper w/ setuid
            bwrap = {
              owner = "root";
              group = "root";
              source = "${pkgs.bubblewrap}/bin/bwrap";
              setuid = true;
            };
          };
  
          environment = {
            systemPackages = with pkgs; [
              # Install steam w/ bubblewrap wrapper
              (steam.override {
                buildFHSEnv = buildFHSEnv.override {
                  bubblewrap = "${config.security.wrapperDir}/..";
                };
                steam-unwrapped = pkgs.callPackage ./pkgs/steam-unwrapped {};
              })
              # Install steam-session script
              (writeShellScriptBin "steam-session" ''
                #!/bin/sh
                if [ -r $XDG_RUNTIME_DIR/switch-to-desktop ]; then
                  rm $XDG_RUNTIME_DIR/switch-to-desktop
                  exec ${cfg.desktopSession}
                else
                  exec ${config.security.wrapperDir}/gamescope \
                  ${lib.concatStringsSep " " ([
                    "--steam"
                    "--mangoapp"
                    "--fullscreen"
                    "--rt"
                    "--immediate-flips"
                    "--force-grab-cursor"
                  ] ++ lib.optionals cfg.enableHDR [ "--hdr-enabled" "--hdr-itm-enable" ]
                    ++ lib.optionals cfg.enableVRR [ "--adaptive-sync" ])} -- \
                  steam -steamos3 -tenfoot -pipewire-dmabuf \
                  > /dev/null 2>&1
                fi
              '')
            ];
            sessionVariables = {
              # Add ~/.local/bin to path
              PATH = [ "/home/${cfg.user}/.local/bin" ];
            };
          };
  
          systemd.tmpfiles.rules = [
            # Ensure ~/.local/bin exists and can be accessed
            "d /home/${cfg.user}/.local/bin 0755 ${cfg.user} users -"
            # Create steamos-session-select and symlink to ~/.local/bin
            "L+ /home/${cfg.user}/.local/bin/steamos-session-select - - - - ${
              pkgs.writeTextFile {
                name = "steamos-session-select";
                text = ''
                  #!/bin/sh
                  touch $XDG_RUNTIME_DIR/switch-to-desktop
                  steam -shutdown
                '';
                executable = true;
              }
            }"
          ];

          users.users.steamuser = {
            isNormalUser = true;
            extraGroups = [ "networkmanager" ];
          };
  
          services = {
            # Make steam-session the default session w/ greetd
            greetd = {
              enable = true;
              settings.default_session = {
                command = "steam-session";
                user = "steamuser";
              };
            };
            # Force disable the other display managers
            #displayManager.sddm.enable = lib.mkForce false;
            #xserver.displayManager.gdm.enable = lib.mkForce false;
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
        (lib.mkIf cfg.enablePlymouth {
          # todo
        })
      ]);
    };
  };
}
