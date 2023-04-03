FROM ubuntu:lunar

ENV DEBIAN_FRONTEND=noninteractive

ARG POWERSHELL_VER=7.3.3
ARG POWERSHELL_MSI=PowerShell-${POWERSHELL_VER}-win-x64.msi
ARG POWERSHELL_URL=https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VER}/${POWERSHELL_MSI}


RUN dpkg --add-architecture i386 && \
    apt update -y && \
    apt install -y wget && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources && \
    apt update -y && \
    apt install -y --install-recommends winehq-staging \
                   cabextract \
                   libvulkan1 \
                   xvfb \
                   xdotool \
                   x11vnc \
                   wget \
                   unzip \
                   file && \
  wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
  chmod +x winetricks && \
  mv winetricks /usr/bin

ENV DISPLAY=:0
ENV WINEARCH=win64

RUN xvfb-run -a bash -c 'winecfg & x11vnc; wait $(jobs -p)'

RUN xvfb-run -a bash -c 'winetricks dotnetcore2 & x11vnc; wait $(jobs -p)'
RUN xvfb-run -a bash -c 'winetricks dotnetcore3 & x11vnc; wait $(jobs -p)'

RUN xvfb-run -a bash -c 'winetricks dotnet48 & x11vnc; wait $(jobs -p)'
RUN xvfb-run -a bash -c 'winecfg & x11vnc; wait $(jobs -p)'

RUN wget ${POWERSHELL_URL} && \
    xvfb-run -a bash -c 'wine msiexec /i ${POWERSHELL_MSI} & x11vnc; wait $(jobs -p)' && \
    rm ${POWERSHELL_MSI}

ENV WINEDEBUG=-all

ARG CHOCOLATEY_INSTALL_SCRIPT="Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

RUN xvfb-run -a bash -c "wineconsole pwsh -c \"${CHOCOLATEY_INSTALL_SCRIPT}\" & x11vnc; wait \$(jobs -p)"
RUN xvfb-run -a bash -c 'wineconsole pwsh -c choco install -y --force nuget.commandline & x11vnc; wait $(jobs -p)'
RUN xvfb-run -a bash -c 'wineconsole pwsh -c choco install -y --force asmspy & x11vnc; wait $(jobs -p)';

ARG GIT_VER=2.40.0
ARG GIT_EXE=Git-${GIT_VER}-64-bit.exe
ARG GIT_URL=https://github.com/git-for-windows/git/releases/download/v${GIT_VER}.windows.1/${GIT_EXE}
RUN wget ${GIT_URL} && \
    xvfb-run -a bash -c 'wine ${GIT_EXE} & x11vnc' && \
    rm ${GIT_EXE}


ARG PYTHON_VER=3.10.10
ARG PYTHON_EXE=python-${PYTHON_VER}-amd64.exe
ARG PYTHON_URL=https://www.python.org/ftp/python/${PYTHON_VER}/${PYTHON_EXE}
RUN wget ${PYTHON_URL} && \
    xvfb-run -a bash -c 'wine ${PYTHON_EXE} & x11vnc; wait $(jobs -p)' && \
    rm ${PYTHON_EXE}


#ARG MSYS_EXE=msys2-x86_64-20230318.exe
#ARG MSYS_URL=https://github.com/msys2/msys2-installer/releases/download/2023-03-18/${MSYS_EXE}
#RUN wget ${MSYS_URL} && \
#    xvfb-run -a bash -c 'wine ${MSYS_EXE} & x11vnc; wait $(jobs -p)' && \
#    rm ${MSYS_EXE}


ARG PERL_VER=5.32.1.1
ARG PERL_MSI=strawberry-perl-${PERL_VER}-64bit.msi
ARG PERL_URL=https://strawberryperl.com/download/${PERL_VER}/${PERL_MSI}
RUN wget ${PERL_URL} && \
    xvfb-run -a bash -c 'wine ${PERL_MSI} & x11vnc; wait $(jobs -p)' && \
    rm ${PERL_MSI}


ARG CMAKE_VER=3.26.2
ARG CMAKE_MSI=cmake-${CMAKE_VER}-windows-x86_64.msi
ARG CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/${CMAKE_MSI}
RUN wget ${CMAKE_URL} && \
    xvfb-run -a bash -c 'wine ${CMAKE_MSI} & x11vnc; wait $(jobs -p)' && \
    rm ${CMAKE_MSI}


ARG MICROSOFT_URL=https://download.microsoft.com/download
ARG BUILDTOOLS_2015=BuildTools_Full.exe
ARG BUILDTOOLS_2015_URL=${MICROSOFT_URL}/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/${BUILDTOOLS_2015}
RUN wget ${BUILDTOOLS_2015_URL} && \
    xvfb-run -a bash -c 'wine ${BUILDTOOLS_2015} & x11vnc; wait $(jobs -p)' && \
    rm ${BUILDTOOLS_2015}


ARG NSIS_EXE=nsis-3.08-setup.exe
ARG NSIS_URL=https://prdownloads.sourceforge.net/nsis/${NSIS_EXE}
RUN wget ${NSIS_URL} && \
    xvfb-run -a bash -c 'wine ${NSIS_EXE} & x11vnc; wait $(jobs -p)' && \
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


ARG BASE_PROGRAM_FILES_URL=https://github.com/readysloth/msvc-wine/releases/download/v0.0.2
ARG PROGRAM_FILES_ZIP=${BASE_PROGRAM_FILES_URL}/program_files.zip

ARG PROGRAM_FILES_X86_ZIP1=${BASE_PROGRAM_FILES_URL}/program_filesx86.zip.xaa
ARG PROGRAM_FILES_X86_ZIP2=${BASE_PROGRAM_FILES_URL}/program_filesx86.zip.xab

RUN wget ${PROGRAM_FILES_ZIP} ${PROGRAM_FILES_X86_ZIP1} ${PROGRAM_FILES_X86_ZIP2} && \
    cat program_filesx86.zip.xaa program_filesx86.zip.xab > program_filesx86.zip && \
    unzip program_files.zip && \
    unzip program_filesx86.zip && \
    rm -v *.zip* && \
    cp -vr mnt/* ~/.wine/drive_c/ && \
    rm -vrf mnt


ARG WDK_URL=https://go.microsoft.com/fwlink/p/?LinkId=526733
ARG WDK_EXE=wdksetup.exe
RUN wget --content-disposition ${WDK_URL} && \
    xvfb-run -a bash -c 'wine ${WDK_EXE} & x11vnc; wait $(jobs -p)' && \
    rm ${WDK_EXE}


ARG BASE_REG_URL=https://github.com/readysloth/msvc-wine/raw/main/reg
ARG WOW6432_REG=${BASE_REG_URL}/wow6432.reg

ARG MICROSOFT_REG1=${BASE_REG_URL}/microsoft/xaa
ARG MICROSOFT_REG2=${BASE_REG_URL}/microsoft/xab

RUN wget ${WOW6432_REG} ${MICROSOFT_REG1} ${MICROSOFT_REG2} && \
    cat xaa xab > microsoft.reg && \
    xvfb-run -a bash -c 'wine regedit.exe & x11vnc; wait $(jobs -p)' && \
    rm *.reg xa*

RUN find ~/.wine -name 'vcvars*' -type f -print0 | xargs -0 sed -i s/@//g


ARG JFROG_SCRIPT="iwr https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe -OutFile $env:SYSTEMROOT\system32\jf.exe"
RUN wget 'https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/[RELEASE]/jfrog-cli-windows-amd64/jf.exe' \
    -O ${MISC_TOOLS_PATH}/jf.exe && \
    bash -c 'cp ${MISC_TOOLS_PATH}/{jf,jfrog}.exe'
