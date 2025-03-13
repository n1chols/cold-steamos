{ lib
, fetchFromGitHub
, nodejs
, pnpm_9
, python3
, coreutils
, psmisc
}:

python3.pkgs.buildPythonPackage rec {
  pname = "decky-loader";
  version = "3.1.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "SteamDeckHomebrew";
    repo = "decky-loader";
    rev = "v${version}";
    hash = "sha256-wJCSjuZJTYtFVtvVHhfvrxQAUcaI/GT93E2Lcok5Yvk=";
  };

  # Frontend build dependencies
  nativeBuildInputs = [ nodejs pnpm_9.configHook ];

  # Python build system
  build-system = with python3.pkgs; [ poetry-core ];

  # Runtime dependencies
  dependencies = with python3.pkgs; [
    aiohttp
    aiohttp-cors
    aiohttp-jinja2
    certifi
    multidict
    packaging
    setproctitle
    watchdog
  ];

  # Build frontend before backend
  preBuild = ''
    cd frontend
    pnpm install --frozen-lockfile
    pnpm build
    cd ../backend
  '';

  # Add utilities to PATH for scripts
  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ coreutils psmisc ]}" ];
}
