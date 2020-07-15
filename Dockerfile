FROM mcr.microsoft.com/dotnet/core/sdk:3.1

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]