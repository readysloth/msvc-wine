FROM ubuntu:lunar

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt update -y && \
    apt install -y wget gnupg && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources && \
    echo "deb http://ppa.launchpad.net/apt-fast/stable/ubuntu bionic main" >> /etc/apt/sources.list && \
    echo "deb-src http://ppa.launchpad.net/apt-fast/stable/ubuntu bionic main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A2166B8DE8BDC3367D1901C11EE2FF37CA8DA16B && \
    apt update -y && apt -y install apt-fast && \
    apt install -y aria2 && \
    apt-fast install -y --install-recommends winehq-staging \
                   cabextract \
                   winbind \
                   libvulkan1 \
                   xvfb \
                   xdotool \
                   x11vnc \
                   wget \
                   unzip \
                   file \
                   dos2unix \
                   git \
                   vim \
                   less \
                   locales \
                   locales-all && \
  wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
  chmod +x winetricks && \
  mv winetricks /usr/bin

ARG WINE_START="wine cmd /c start /wait"
ARG WINE_END="wineserver --wait"
ARG CLEANUP_DIRS="/root/.wine/drive_c/users/root/Temp/ /win_pkg_cache"
ARG CLEANUP="find -L ${CLEANUP_DIRS} -maxdepth 1 -mindepth 1 -exec rm -vrf {} ;"
ARG MSI_INSTALL="${WINE_START} msiexec /i"
ARG MSI_INSTALL_OPTS="/qn"
ARG PATH_REGISTRY_KEY="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
ARG MISC_TOOLS_PATH="/root/.wine/drive_c/dev_tools"
ARG ARCHIVES_BASE_URL="https://github.com/readysloth/msvc-wine/releases/download"
ARG SDK_WDK_VERSION="10.0.14393.0"
ARG WIN_MISC_TOOLS_PATH="C:\dev_tools"
ARG WGET="aria2c"

ENV DISPLAY=:0
ENV WINEARCH=win64
ENV WINDEBUG=-all
ENV WINETRICKS_DOWNLOADER="${WGET}"


RUN WINEDLLOVERRIDES=mscoree=d wineboot && ${WINE_END} && \
    ln -s "/root/.wine/drive_c/ProgramData/Package Cache" /win_pkg_cache && \
    ${CLEANUP}
RUN winecfg /v win10 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f dotnetcore3 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f dotnetcoredesktop3 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f dotnet48 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f vcrun6 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f mfc42 && ${WINE_END} && ${CLEANUP}
RUN winetricks -q -f mingw && ${WINE_END} && ${CLEANUP}
RUN winecfg /v win10 && ${WINE_END} && ${CLEANUP}
RUN mkdir ${MISC_TOOLS_PATH}


RUN export WIN_PATH="$(wine reg query "${PATH_REGISTRY_KEY}" /v Path | \
                       dos2unix | \
                       grep -i PATH | \
                       awk -F'REG_[^[:space:]]*SZ[[:space:]]*' '{print $2}' | \
                       tr -dc '[[:print:]]')" && \
    wine reg add "${PATH_REGISTRY_KEY}"\
             /v Path \
             /t REG_EXPAND_SZ \
             /d "${WIN_PATH};${WIN_MISC_TOOLS_PATH};C:\\MinGW\\msys\\1.0\\bin" /f && \
    ${WINE_END}


ARG POWERSHELL_VER=7.3.3
ARG POWERSHELL_MSI=PowerShell-${POWERSHELL_VER}-win-x64.msi
ARG POWERSHELL_URL=https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VER}/${POWERSHELL_MSI}
RUN ${WGET} ${POWERSHELL_URL} && \
    ${MSI_INSTALL} ${POWERSHELL_MSI} ALL_USERS=1 ADD_PATH=1 USE_MU=0 ENABLE_MU=0 ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${POWERSHELL_MSI}

RUN winecfg /v win10 && ${WINE_END} && ${CLEANUP}

ARG CHOCOLATEY_INSTALL_SCRIPT="Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

RUN ${WINE_START} pwsh -c "${CHOCOLATEY_INSTALL_SCRIPT}" && ${WINE_END} && ${CLEANUP}
RUN ${WINE_START} pwsh -c choco install -y --force nuget.commandline && ${WINE_END} && ${CLEANUP}
RUN ${WINE_START} pwsh -c choco install -y --force asmspy && ${WINE_END} && ${CLEANUP}


ARG LLVM_VER=16.0.0
ARG LLVM_EXE=LLVM-${LLVM_VER}-win64.exe
ARG LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/${LLVM_EXE}
ARG LLVM_INSTALL_OPTS="/S"
RUN ${WGET} ${LLVM_URL} && \
    echo "${WINE_START} ${LLVM_EXE} ${LLVM_INSTALL_OPTS}" && \
    ${WINE_START} ${LLVM_EXE} ${LLVM_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    export WIN_PATH="$(wine reg query "${PATH_REGISTRY_KEY}" /v Path | \
                       dos2unix | \
                       grep -i PATH | \
                       awk -F'REG_[^[:space:]]*SZ[[:space:]]*' '{print $2}' | \
                       tr -dc '[[:print:]]')" && \
    wine reg add "${PATH_REGISTRY_KEY}"\
             /v Path \
             /t REG_EXPAND_SZ \
             /d "${WIN_PATH};C:\\Program Files\\LLVM\\bin" /f && \
    ${WINE_END} && \
    ln -s ~/.wine/drive_c/Program\ Files/LLVM/bin/clang-cl.exe ~/.wine/drive_c/Program\ Files/LLVM/bin/cl.exe && \
    rm ${LLVM_EXE}


ARG PYTHON_VER=3.10.10
ARG PYTHON_EXE=python-${PYTHON_VER}-amd64.exe
ARG PYTHON_URL=https://www.python.org/ftp/python/${PYTHON_VER}/${PYTHON_EXE}
ARG PYTHON_INSTALL_OPTS='/quiet InstallAllUsers=1 CompileAll=1 PrependPath=1 Include_launcher=1'
RUN ${WGET} ${PYTHON_URL} && \
    echo "${WINE_START} ${PYTHON_EXE} ${PYTHON_INSTALL_OPTS}" && \
    ${WINE_START} ${PYTHON_EXE} ${PYTHON_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${PYTHON_EXE}


ARG GIT_VER=2.40.0
ARG GIT_EXE=Git-${GIT_VER}-64-bit.exe
ARG GIT_URL=https://github.com/git-for-windows/git/releases/download/v${GIT_VER}.windows.1/${GIT_EXE}
ARG GIT_INSTALL_OPTS='/VERYSILENT /NORESTART /NOCANCEL /SP- /ALLUSERS /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="ext\shellhere,assoc,assoc_sh"'
# Git hangs on post-install
RUN ${WGET} ${GIT_URL} && \
    timeout 5m ${WINE_START} ${GIT_EXE} ${GIT_INSTALL_OPTS}; wineserver -k 9 && \
    rm ${GIT_EXE}


ARG PERL_VER=5.32.1.1
ARG PERL_MSI=strawberry-perl-${PERL_VER}-64bit.msi
ARG PERL_URL=https://strawberryperl.com/download/${PERL_VER}/${PERL_MSI}
RUN ${WGET} ${PERL_URL} && \
    ${MSI_INSTALL} ${PERL_MSI} ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${PERL_MSI}


ARG CMAKE_VER=3.26.2
ARG CMAKE_MSI=cmake-${CMAKE_VER}-windows-x86_64.msi
ARG CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/${CMAKE_MSI}
ARG CMAKE_INSTALL_OPTS="ADD_CMAKE_TO_PATH=System "
RUN ${WGET} ${CMAKE_URL} && \
    ${MSI_INSTALL} ${CMAKE_MSI} ${CMAKE_INSTALL_OPTS} ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${CMAKE_MSI}


ARG NSIS_EXE=nsis-3.08-setup.exe
ARG NSIS_URL=https://prdownloads.sourceforge.net/nsis/${NSIS_EXE}
ARG NSIS_INSTALL_OPTS="/S /NCRC"
RUN ${WGET} ${NSIS_URL} && \
    ${WINE_START} ${NSIS_EXE} ${NSIS_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${NSIS_EXE}


ARG WIX_ZIP=wix311-binaries.zip
ARG WIX_URL=https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/${WIX_ZIP}
RUN ${WGET} ${WIX_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${WIX_ZIP} && \
    rm ${WIX_ZIP}


ARG DEPENDENCIES_VER=1.11.1
ARG DEPENDENCIES_ZIP=Dependencies_x64_Release.zip
ARG DEPENDENCIES_URL=https://github.com/lucasg/Dependencies/releases/download/v${DEPENDENCIES_VER}/${DEPENDENCIES_ZIP}
RUN ${WGET} ${DEPENDENCIES_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${DEPENDENCIES_ZIP} && \
    rm ${DEPENDENCIES_ZIP}


ARG DEPENDENCY_WALKER_ZIP=depends22_x64.zip
ARG DEPENDENCY_WALKER_URL=http://www.dependencywalker.com/${DEPENDENCY_WALKER_ZIP}
RUN ${WGET} ${DEPENDENCY_WALKER_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${DEPENDENCY_WALKER_ZIP} && \
    rm ${DEPENDENCY_WALKER_ZIP}


ARG NINJA_VER=1.11.1
ARG NINJA_ZIP=ninja-win.zip
ARG NINJA_URL=https://github.com/ninja-build/ninja/releases/download/v${NINJA_VER}/ninja-win.zip
RUN ${WGET} ${NINJA_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${NINJA_ZIP} && \
    rm ${NINJA_ZIP}


ARG W64DEVKIT_VER=1.18.0
ARG W64DEVKIT_ZIP=w64devkit-${W64DEVKIT_VER}.zip
ARG W64DEVKIT_URL=https://github.com/skeeto/w64devkit/releases/download/v${W64DEVKIT_VER}/${W64DEVKIT_ZIP}
RUN ${WGET} ${W64DEVKIT_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${W64DEVKIT_ZIP} && \
    rm ${W64DEVKIT_ZIP}


ARG DNSPY_VER=6.3.0
ARG DNSPY_ZIP=dnSpy-net-win64.zip
ARG DNSPY_URL=https://github.com/dnSpyEx/dnSpy/releases/download/v${DNSPY_VER}/${DNSPY_ZIP}
RUN ${WGET} ${DNSPY_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${DNSPY_ZIP} && \
    rm ${DNSPY_ZIP}


ARG X64DBG_ZIP=snapshot_2023-04-15_16-57.zip
ARG X64DBG_URL=https://github.com/x64dbg/x64dbg/releases/download/snapshot/${X64DBG_ZIP}
RUN ${WGET} ${X64DBG_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${X64DBG_ZIP} && \
    rm ${X64DBG_ZIP} && \
    export WIN_PATH="$(wine reg query "${PATH_REGISTRY_KEY}" /v Path | \
                       dos2unix | \
                       grep -i PATH | \
                       awk -F'REG_[^[:space:]]*SZ[[:space:]]*' '{print $2}' | \
                       tr -dc '[[:print:]]')" && \
    wine reg add "${PATH_REGISTRY_KEY}"\
             /v Path \
             /t REG_EXPAND_SZ \
             /d "${WIN_PATH};C:\\dev_tools\\release" /f && \
    ${WINE_END}


RUN ${WINE_START} pip install cmake-converter && ${WINE_END}


ARG JFROG_SCRIPT="iwr https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe -OutFile $env:SYSTEMROOT\system32\jf.exe"
RUN wget 'https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe' \
    -O ${MISC_TOOLS_PATH}/jf.exe && \
    bash -c "cp ${MISC_TOOLS_PATH}/{jf,jfrog}.exe"

COPY cmd-win.exe ${MISC_TOOLS_PATH}
COPY cmd-reactos.exe ${MISC_TOOLS_PATH}

ENV WINEDEBUG=-all

RUN echo "wine cmd /c ${MISC_TOOLS_PATH}/w64devkit/w64devkit.exe" > /startup.sh && \
    chmod +x /startup.sh


ARG EWDK_WIN_PATH="${WIN_MISC_TOOLS_PATH}\EWDK"
ARG EWDK_PROGRAM_FILES_PATH="${EWDK_WIN_PATH}\Program Files"
ARG EWDK_SDK_DIR_WIN_PATH="${EWDK_PROGRAM_FILES_PATH}\Windows Kits\10"
ARG EWDK_BASE_INCLUDE_PATH="${EWDK_SDK_DIR_WIN_PATH}\Include\\${SDK_WDK_VERSION}"
ARG EWDK_BASE_LIB_PATHS="${EWDK_SDK_DIR_WIN_PATH}\Lib\\${SDK_WDK_VERSION}"

ARG EBIP="${EWDK_BASE_INCLUDE_PATH}"
ARG MSVS="${EWDK_PROGRAM_FILES_PATH}\Microsoft Visual Studio 14.0\VC"

ARG EWDK_INCLUDE_PATHS="${EBIP}\km;${EBIP}\shared;${EBIP}\ucrt;${EBIP}\um;${MSVS}\atlmfc\include;${MSVS}\include"
ARG EWDK_LIB_PATHS="${EWDK_BASE_LIB_PATHS}\um\x64;${EWDK_BASE_LIB_PATHS}\ucrt\x64;${MSVS}\lib\amd64;${MSVS}\redist\x64\Microsoft.VC140.CRT;${MSVS}\atlmfc\lib\amd64"

ARG EWDK_ZIP=EnterpriseWDK_rs1_release_14393_20160715-1616.zip
ARG EWDK_URL=https://go.microsoft.com/fwlink/p/?LinkID=699461
RUN ${WGET} ${EWDK_URL} && \
    mkdir ${MISC_TOOLS_PATH}/EWDK && \
    unzip -d ${MISC_TOOLS_PATH}/EWDK ${EWDK_ZIP} && \
    sed -i 91d ${MISC_TOOLS_PATH}/EWDK/BuildEnv/SetupBuildEnv.cmd && \
    rm -vrf ~/.wine/drive_c/windows/Installer/*; \
    find ~/'.wine/drive_c/' -name '*.vsix' -type d -print0 | xargs -0 rm -vrf; \
    find ~/'.wine/drive_c/' -name 'arm*' -type d -print0 | xargs -0 rm -vrf; \
    find ~/.wine -type f -name '*.pdb' -print0 | xargs -0 rm -vrf; \
    wine reg add "${PATH_REGISTRY_KEY}"\
             /v INCLUDE \
             /t REG_EXPAND_SZ \
             /d "${EWDK_INCLUDE_PATHS}" /f && \
    wine reg add "${PATH_REGISTRY_KEY}"\
             /v LIB \
             /t REG_EXPAND_SZ \
             /d "${EWDK_LIB_PATHS}" /f && \
    ${WINE_END} && \
    rm ${EWDK_ZIP}

ENTRYPOINT /startup.sh
