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
  pname = "decky-loader";
  version = "3.1.5";

  src = fetchFromGitHub {
    owner = "SteamDeckHomebrew";
    repo = "decky-loader";
    rev = "v${version}";
    hash = "sha256-2unRxeN2fhkkcOmiWh7OUxJtC65VKX1Zi8xyIP+M5lw=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    sourceRoot = "${src.name}/frontend";
    hash = "sha256-WzYbqcniww6jpLu1PIJ3En/FPZSqOZuK6fcwN1mxuNQ=";
  };

  pnpmRoot = "frontend";

  pyproject = true;

  nativeBuildInputs = [ nodejs pnpm_9.configHook ];

  build-system = with python3.pkgs; [ poetry-core poetry-dynamic-versioning ];

  preBuild = ''
    cd frontend
    pnpm build
    cd ../backend
  '';

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

  pythonRelaxDeps = [ "aiohttp" "watchdog" ];

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ coreutils psmisc ]}" ];

  passthru.python = python3;
}
