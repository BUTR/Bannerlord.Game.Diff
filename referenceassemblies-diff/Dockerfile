FROM mcr.microsoft.com/dotnet/sdk:5.0

ARG NODE_VERSION=16
RUN apt-get update -y && \
    apt-get install curl tree -y && \    
    curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists;    

RUN npm install -g diff2html-cli && \
	dotnet new tool-manifest --name local && \
    dotnet tool install ilspycmd --version 8.0.0.7106-preview2

COPY . .

LABEL org.opencontainers.image.source="https://github.com/BUTR/Bannerlord.Game.Diff"

ENV OLD_VERSION_FOLDER=""
ENV NEW_VERSION_FOLDER=""
ENV STABLE_VERSION=""
ENV BETA_VERSION=""
ENV TOKEN=""
CMD pwsh ./generate-diffs.ps1 -old_version_folder $OLD_VERSION_FOLDER -new_version_folder $NEW_VERSION_FOLDER -stable_version $STABLE_VERSION -beta_version $BETA_VERSION -token $TOKEN