FROM mcr.microsoft.com/dotnet/sdk:6.0

ARG NODE_VERSION=16
RUN apt-get update -y && \
    apt-get install curl unzip wget tree -y && \    
    curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists;    

RUN wget https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.4.6/depotdownloader-2.4.6.zip && \
    unzip depotdownloader-2.4.6.zip -d depotdownloader && \
    rm depotdownloader-2.4.6.zip && \
    npm install -g diff2html-cli && \
	dotnet new tool-manifest --name local && \
    dotnet tool install dotnet-script && \
    dotnet tool install ilspycmd --version 8.0.0.7106-preview2 &&

COPY . .

LABEL org.opencontainers.image.source="https://github.com/BUTR/Bannerlord.Game.Diff"

ENV STEAM_LOGIN=""
ENV STEAM_PASSWORD=""
ENV STABLE_VERSION=""
ENV BETA_VERSION=""
ENV HTML_PATH=""
CMD dotnet-script ./main.csx $STABLE_VERSION $BETA_VERSION $STEAM_LOGIN $STEAM_PASSWORD $HTML_PATH