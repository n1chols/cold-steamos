## nixos-steam-console
A simple flake to turn any NixOS device into a SteamOS console. Inspired by Jovian-NixOS.

### Features
- Gamescope realtime capabilty by default
- Configurable 'Switch to Desktop' session
- Decky Loader

### Usage
```nixos
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    simple-system.url = "github:n1chols/nixos-simple-system";
    steam-console.url = "github:n1chols/nixos-steam-console";
  };

  outputs = { simple-system, steam-console, ... }: {
    nixosConfigurations.htpc = simple-system {
      hostName = "htpc";
      userName = "user";

      cpuVendor = "amd";
      gpuVendor = "amd";

      bootDevice = "/dev/nvme0n1p1";
      rootDevice = "/dev/nvme0n1p2";
      swapDevice = "/dev/nvme0n1p3";

      gamingTweaks = true;
      hiResAudio = true;
      gamepad = true;

      modules = [
        ./modules/gnome.nix
        steam-console.nixosModules.default
        ({ pkgs, ... }: {
          steam-console = {
            enable = true;
            enableHDR = true;
            enableVRR = true;
            enableDecky = true;
            user = "user";
            desktopSession = "XDG_SESSION_TYPE=wayland dbus-run-session gnome-session";
          };
        })
      ];
    };
  };
}
```
