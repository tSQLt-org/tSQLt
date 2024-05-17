# Use the specified image as the base
FROM mcr.microsoft.com/devcontainers/base:bullseye

# Set environment variables, if any
# ENV MY_ENV_VAR=my_value

# Run package updates and install packages
RUN apt-get update 


CMD code --install-extension ms-mssql.mssql

USER vscode
RUN curl https://run.spawn.cc/install | sh
ENV PATH="/home/vscode/.spawnctl/bin:$PATH"

USER root
RUN apt-get update && apt-get install -y curl gnupg software-properties-common \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh

RUN apt-get update && \
    apt-get install -y mono-complete

ENV TSQLTCERTPATH /var/tSQLtCertTemp
ENV TSQLTCERTPASSWORD P@ssw0rdP@ssw0rdP@ssw0rdP@ssw0rd
RUN mkdir -p $TSQLTCERTPATH && \
    chmod 777 $TSQLTCERTPATH

# Add the Microsoft SQL Server repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/msprod.list

RUN apt-get update
ENV ACCEPT_EULA=Y
RUN apt-get install -y mssql-tools unixodbc-dev
ENV PATH="$PATH:/opt/mssql-tools/bin"

RUN apt-get install -y unzip

RUN curl -L https://aka.ms/sqlpackage-linux -o sqlpackage.zip \
    && unzip sqlpackage.zip -d /opt/sqlpackage \
    && chmod +x /opt/sqlpackage/sqlpackage \
    && rm sqlpackage.zip
ENV PATH="$PATH:/opt/sqlpackage"

RUN apt-get install -y wget apt-transport-https software-properties-common && \
    wget -q "https://packages.microsoft.com/config/debian/$(. /etc/os-release && echo $VERSION_ID)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

RUN pwsh -Command "Install-Module -Name SqlServer -Scope AllUsers -AllowClobber -Force"

RUN pwsh -Command "Install-Module -Name Az -AllowClobber -Scope AllUsers -Force"
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

# Set the default shell to PowerShell
SHELL ["pwsh", "-Command"]


