{
  lib,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
  python3,
  coreutils,
  psmisc
}:

python3.pkgs.buildPythonPackage rec {
  # Package info
  pname = "decky-loader";
  version = "3.1.3";

  # GitHub source
  src = fetchFromGitHub {
    owner = "SteamDeckHomebrew";
    repo = "decky-loader";
    rev = "v${version}";
    hash = "sha256-wJCSjuZJTYtFVtvVHhfvrxQAUcaI/GT93E2Lcok5Yvk=";
  };

  # Frontend dependencies
  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    sourceRoot = "${src.name}/frontend";
    hash = "sha256-WzYbqcniww6jpLu1PIJ3En/FPZSqOZuK6fcwN1mxuNQ=";
  };

  pnpmRoot = "frontend";

  # Build environment setup
  pyproject = true;

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
  ];

  build-system = with python3.pkgs; [
    poetry-core
    poetry-dynamic-versioning
  ];

  # Build steps
  preBuild = ''
    cd frontend
    pnpm build
    cd ../backend
  '';

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

  pythonRelaxDeps = [ "watchdog" ];

  # Wrapper configuration
  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ coreutils psmisc ]}"
  ];

  # Additional attributes
  passthru.python = python3;
}
