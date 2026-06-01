# You can pick any Debian/Ubuntu-based image. 😊
FROM mcr.microsoft.com/vscode/devcontainers/base:trixie

# Add OpenTofu repo
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg \
  && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
    | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
  && chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" \
    > /etc/apt/sources.list.d/opentofu.list \
  && chmod a+r /etc/apt/sources.list.d/opentofu.list

# Install OpenTofu
RUN apt-get update && apt-get install -y tofu && rm -rf /var/lib/apt/lists/*
