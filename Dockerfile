FROM mcr.microsoft.com/dotnet/core/sdk:3.1

RUN mkdir /tools

RUN dotnet tool install --tool-path /tools Microsoft.CST.DevSkim.Cli

COPY entrypoint.sh /entrypoint.sh

RUN chmod 777 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]