# Install the .NET Core tool as before
FROM mcr.microsoft.com/dotnet/sdk:6.0 as builder

RUN dotnet tool install --global ilspycmd --version 8.0.0.7106-preview2 && \
    dotnet tool install --global dotnet-script

ENV PATH="/root/.dotnet/tools:${PATH}"

FROM mcr.microsoft.com/dotnet/runtime:6.0

ARG NODE_VERSION=16
RUN apt-get update -y && \
    apt-get install curl unzip wget tree -y && \    
    curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists;    

RUN wget https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.4.6/depotdownloader-2.4.6.zip && \
    unzip depotdownloader-2.4.6.zip -d depotdownloader && \
    rm depotdownloader-2.4.6.zip && \
    npm install -g diff2html-cli

COPY --from=builder /root/.dotnet/tools/ /opt/bin
ENV PATH="/opt/bin:${PATH}"

COPY . .

ENV STEAM_LOGIN=""
ENV STEAM_PASSWORD=""
ENV STABLE_VERSION=""
ENV BETA_VERSION=""
ENV HTML_PATH=""
CMD dotnet-script ./main.csx $STABLE_VERSION $BETA_VERSION $STEAM_LOGIN $STEAM_PASSWORD $HTML_PATH