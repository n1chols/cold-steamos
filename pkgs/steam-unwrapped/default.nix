{
  steam-unwrapped,
  fetchurl
}:

let
  bootstrapVersion = "1.0.0.81-2.2";
  bundle = fetchurl {
    url = "https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-main/steam-jupiter-stable-${bootstrapVersion}.src.tar.gz";
    hash = "sha256-PAA1fV7JZSv07cXewtAjwD96gUwuAde2P+Pg+bGQkPY=";
  };
in steam-unwrapped.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    tar xvf ${bundle}
    cp steam-jupiter-stable/steam_jupiter_stable_bootstrapped_*.tar.xz $out/lib/steam/bootstraplinux_ubuntu12_32.tar.xz
  '';
})
