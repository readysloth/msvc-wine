# msvc-wine

This repo contains Dockerfile that installs needed software to develop software for Windows.
Mainly it uses Wine and EWDK of specific version to match my build requirements.
You can easily change it after reading source code.

Default entrypoint is MinGW64, but if you want to use EWDK facilities, execute container with
option `--entrypoint bash`, then open cmd via `wine cmd` and initialize environment
calling `C:\dev_tools\EWDK\BuildEnv\SetupBuildEnv.cmd amd64`. After that you should be able to
call MSBuild, CL and etc.

If you encounter problems with encoding of builded programs, then change encoding via `export LANG`
before launching wine

# which cmd?

CMD implemented by WINE struggle to run complex batch scripts, it is possible to overcome by installing CMD.exe from ReactOS,
so, if you encounter problems, use `wine cmd-reactos`
