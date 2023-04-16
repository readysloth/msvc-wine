FROM ubuntu:lunar

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt update -y && \
    apt install -y wget && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources && \
    apt update -y && \
    apt install -y --install-recommends winehq-staging \
                   cabextract \
                   winbind \
                   libvulkan1 \
                   xvfb \
                   xdotool \
                   x11vnc \
                   wget \
                   unzip \
                   file \
                   vim \
                   less && \
  wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
  chmod +x winetricks && \
  mv winetricks /usr/bin

ENV DISPLAY=:0
ENV WINEARCH=win64
ENV WINDEBUG=-all

ARG WINE_START="wine cmd /c start /wait"
ARG WINE_END="wineserver --wait"
ARG CLEANUP_DIRS="/root/.wine/drive_c/users/root/Temp/ /win_pkg_cache"
ARG CLEANUP="find -L ${CLEANUP_DIRS} -maxdepth 1 -mindepth 1 -exec rm -vrf {} ;"
ARG MSI_INSTALL="${WINE_START} msiexec /i"
ARG MSI_INSTALL_OPTS="/qn"

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

ARG ARCHIVES_BASE_URL=https://github.com/readysloth/msvc-wine/releases/download

ARG WDK_URL=https://go.microsoft.com/fwlink/p/?LinkId=526733
ARG WDK_EXE=wdksetup.exe
RUN wget --content-disposition ${WDK_URL} && \
    ${WINE_START} ${WDK_EXE} /quiet /installpath 'C:\Program Files (x86)\Windows Kits\10' && ${WINE_END} && ${CLEANUP} && \
    rm ${WDK_EXE}

ARG SDK_ZIP=sdk_layout.zip
ARG SDK_URL=${ARCHIVES_BASE_URL}/v0.0.4/${SDK_ZIP}
RUN wget ${SDK_URL} && \
    unzip ${SDK_ZIP} && \
    cd sdk_layout/Installers && \
    ${MSI_INSTALL} "Orca-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "MsiVal2-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "MSI Development Tools-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Kits Configuration Installer-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Kits Configuration Installer-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Universal CRT Headers Libraries and Sources-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Universal CRT Redistributable-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Universal CRT Tools x64-x64_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Universal CRT Tools x86-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "WPT Redistributables-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "WPTx64-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "WPTx86-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "WinAppDeploy-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK Desktop Headers Libs Metadata-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK Desktop Tools-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK DirectX x64 Remote-x64_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK DirectX x86 Remote-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK Modern Versioned Developer Tools-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK Non-Versioned Legacy Tools-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK Redistributables-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps Contracts-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps DirectX x64 Remote-x64_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps DirectX x86 Remote-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps Headers Libs-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps Tools-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK for Windows Store Apps-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    ${MSI_INSTALL} "Windows SDK-x86_en-us.msi" ${MSI_INSTALL_OPTS} && \
    cd ../.. && \
    rm -vrf ${SDK_ZIP} sdk_layout

ARG POWERSHELL_VER=7.3.3
ARG POWERSHELL_MSI=PowerShell-${POWERSHELL_VER}-win-x64.msi
ARG POWERSHELL_URL=https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VER}/${POWERSHELL_MSI}
RUN wget ${POWERSHELL_URL} && \
    ${MSI_INSTALL} ${POWERSHELL_MSI} ALL_USERS=1 ADD_PATH=1 USE_MU=0 ENABLE_MU=0 ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${POWERSHELL_MSI}

RUN winecfg /v win10 && ${WINE_END} && ${CLEANUP}

ARG CHOCOLATEY_INSTALL_SCRIPT="Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

RUN ${WINE_START} pwsh -c "${CHOCOLATEY_INSTALL_SCRIPT}" && ${WINE_END} && ${CLEANUP}
RUN ${WINE_START} pwsh -c choco install -y --force nuget.commandline && ${WINE_END} && ${CLEANUP}
RUN ${WINE_START} pwsh -c choco install -y --force asmspy && ${WINE_END} && ${CLEANUP}

ARG MICROSOFT_URL=https://download.microsoft.com/download
ARG BUILDTOOLS_2015=BuildTools_Full.exe
ARG BUILDTOOLS_2015_URL=${MICROSOFT_URL}/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/${BUILDTOOLS_2015}
RUN wget ${BUILDTOOLS_2015_URL} && \
    ${WINE_START} ${BUILDTOOLS_2015} /Full /Quiet && ${WINE_END} && \
    rm ${BUILDTOOLS_2015} && \
    rm -vrf ~/.wine/drive_c/windows/Installer/*; \
    find ~/'.wine/drive_c/' -name '*.vsix' -type d -print0 | xargs -0 rm -vrf; \
    find ~/'.wine/drive_c/Program Files (x86)/Windows Kits/10/Lib' -name 'arm*' -type d -print0 | xargs -0 rm -vrf; \
    find ~/'.wine/drive_c/Program Files (x86)/Microsoft Visual Studio 14.0' -name 'arm*' -type d -print0 | xargs -0 rm -vrf; \
    find ~/.wine -name 'vcvars*' -type f -print0 | xargs -0 sed -i s/@//g || true


ARG LLVM_VER=16.0.0
ARG LLVM_EXE=LLVM-${LLVM_VER}-win64.exe
ARG LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/${LLVM_EXE}
ARG LLVM_INSTALL_OPTS="/S"
RUN wget ${LLVM_URL} && \
    echo "${WINE_START} ${LLVM_EXE} ${LLVM_INSTALL_OPTS}" && \
    ${WINE_START} ${LLVM_EXE} ${LLVM_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${LLVM_EXE}


ARG PYTHON_VER=3.10.10
ARG PYTHON_EXE=python-${PYTHON_VER}-amd64.exe
ARG PYTHON_URL=https://www.python.org/ftp/python/${PYTHON_VER}/${PYTHON_EXE}
ARG PYTHON_INSTALL_OPTS='/quiet InstallAllUsers=1 CompileAll=1 PrependPath=1'
RUN wget ${PYTHON_URL} && \
    echo "${WINE_START} ${PYTHON_EXE} ${PYTHON_INSTALL_OPTS}" && \
    ${WINE_START} ${PYTHON_EXE} ${PYTHON_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${PYTHON_EXE}


ARG GIT_VER=2.40.0
ARG GIT_EXE=Git-${GIT_VER}-64-bit.exe
ARG GIT_URL=https://github.com/git-for-windows/git/releases/download/v${GIT_VER}.windows.1/${GIT_EXE}
ARG GIT_INSTALL_OPTS='/VERYSILENT /NORESTART /NOCANCEL /SP- /ALLUSERS /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="ext\shellhere,assoc,assoc_sh"'
# Git hangs on post-install
RUN wget ${GIT_URL} && \
    ${WINE_START} ${GIT_EXE} ${GIT_INSTALL_OPTS} & sleep 5m && wineserver -k 9 && \
    rm ${GIT_EXE}


ARG PERL_VER=5.32.1.1
ARG PERL_MSI=strawberry-perl-${PERL_VER}-64bit.msi
ARG PERL_URL=https://strawberryperl.com/download/${PERL_VER}/${PERL_MSI}
RUN wget ${PERL_URL} && \
    ${MSI_INSTALL} ${PERL_MSI} ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${PERL_MSI}


ARG CMAKE_VER=3.26.2
ARG CMAKE_MSI=cmake-${CMAKE_VER}-windows-x86_64.msi
ARG CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/${CMAKE_MSI}
RUN wget ${CMAKE_URL} && \
    ${MSI_INSTALL} ${CMAKE_MSI} ADD_CMAKE_TO_PATH=System ${MSI_INSTALL_OPTS} && ${WINE_END} && ${CLEANUP} && \
    rm ${CMAKE_MSI}


ARG NSIS_EXE=nsis-3.08-setup.exe
ARG NSIS_URL=https://prdownloads.sourceforge.net/nsis/${NSIS_EXE}
RUN wget ${NSIS_URL} && \
    ${WINE_START} ${NSIS_EXE} /S /NCRC && ${WINE_END} && ${CLEANUP} && \
    rm ${NSIS_EXE}


ARG MISC_TOOLS_PATH=/root/.wine/drive_c/dev_tools
ENV WINEPATH="C:\dev_tools"
RUN mkdir ${MISC_TOOLS_PATH}


ARG DEPENDENCIES_VER=1.11.1
ARG DEPENDENCIES_ZIP=Dependencies_x64_Release.zip
ARG DEPENDENCIES_URL=https://github.com/lucasg/Dependencies/releases/download/v${DEPENDENCIES_VER}/${DEPENDENCIES_ZIP}
RUN wget ${DEPENDENCIES_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${DEPENDENCIES_ZIP} && \
    rm ${DEPENDENCIES_ZIP}


ARG DEPENDENCY_WALKER_ZIP=depends22_x64.zip
ARG DEPENDENCY_WALKER_URL=http://www.dependencywalker.com/${DEPENDENCY_WALKER_ZIP}
RUN wget ${DEPENDENCY_WALKER_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${DEPENDENCY_WALKER_ZIP} && \
    rm ${DEPENDENCY_WALKER_ZIP}


ARG NINJA_VER=1.11.1
ARG NINJA_ZIP=ninja-win.zip
ARG NINJA_URL=https://github.com/ninja-build/ninja/releases/download/v${NINJA_VER}/ninja-win.zip
RUN wget ${NINJA_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${NINJA_ZIP} && \
    rm ${NINJA_ZIP}


ARG W64DEVKIT_VER=1.18.0
ARG W64DEVKIT_ZIP=w64devkit-${W64DEVKIT_VER}.zip
ARG W64DEVKIT_URL=https://github.com/skeeto/w64devkit/releases/download/v${W64DEVKIT_VER}/${W64DEVKIT_ZIP}
RUN wget ${W64DEVKIT_URL} && \
    unzip -d ${MISC_TOOLS_PATH} ${W64DEVKIT_ZIP} && \
    rm ${W64DEVKIT_ZIP}


ARG JFROG_SCRIPT="iwr https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe -OutFile $env:SYSTEMROOT\system32\jf.exe"
RUN wget 'https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe' \
    -O ${MISC_TOOLS_PATH}/jf.exe && \
    bash -c "cp ${MISC_TOOLS_PATH}/{jf,jfrog}.exe"

ENV WINEDEBUG=-all

RUN echo "wine cmd /c ${MISC_TOOLS_PATH}/w64devkit/w64devkit.exe" > /startup.sh && \
    chmod +x /startup.sh

ENTRYPOINT /startup.sh
