# rime
A minimal flake to turn any device into a SteamOS console. Inspired by [Jovian-NixOS](https://github.com/Jovian-Experiments/Jovian-NixOS).

## Features
- 'Switch to Desktop' session
- Gamescope real-time enabled
- HDR/VRR
- [Decky Loader](https://github.com/SteamDeckHomebrew/decky-loader)

## Usage
```nixos
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # Add input:
    steam-console.url = "github:n1chols/rime";
  };

  outputs = { nixpkgs, rime, ... }: {
    nixosConfigurations.steamConsole = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ...
        # Import module:
        rime.modules.default
        ({ ... }: {
          # Configure options:
          rime = {
            enable = true;
            enableHDR = true;
            enableVRR = true;
            enableDecky = true;
            user = "your-user";
            desktopSession = "command-to-start-desktop";
          };
        })
      ];
    };
  };
}
```
