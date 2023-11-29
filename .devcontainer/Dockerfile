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

# Expose any ports the app is expecting to be served on
# EXPOSE 8080

# Set the default command for the container
# CMD ["my-command"]

