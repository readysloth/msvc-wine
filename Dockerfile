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


ARG CACHEBUST=1

RUN wget ${POWERSHELL_URL} && \
    xvfb-run -a bash -c 'wine msiexec /i ${POWERSHELL_MSI} & x11vnc; wait $(jobs -p)' && \
    rm ${POWERSHELL_MSI}

ENV WINEDEBUG=-all


ARG CHOCOLATEY_INSTALL_SCRIPT="Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

RUN xvfb-run -a bash -c "wineconsole pwsh -c \"${CHOCOLATEY_INSTALL_SCRIPT}\" & x11vnc; wait \$(jobs -p)"
RUN xvfb-run -a bash -c 'wineconsole pwsh -c choco install -y --force nuget.commandline & x11vnc; wait $(jobs -p)'
RUN xvfb-run -a bash -c 'wineconsole pwsh -c choco install -y --force asmspy & x11vnc; wait $(jobs -p)';

ARG MICROSOFT_URL=https://download.microsoft.com/download
ARG BUILDTOOLS_2015=BuildTools_Full.exe
ARG BUILDTOOLS_2015_URL=${MICROSOFT_URL}/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/${BUILDTOOLS_2015}

RUN wget ${BUILDTOOLS_2015_URL} && \
    xvfb-run -a bash -c 'wine ${BUILDTOOLS_2015} & x11vnc; wait $(jobs -p)' && \
    rm ${BUILDTOOLS_2015}
