FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
RUN useradd -ms /bin/bash frogger
WORKDIR /home/frogger
ARG JAVA_VERSION=17

# Environment variables
ENV HOME /home/frogger
ENV JAVA_HOME /home/frogger/.sdkman/candidates/java/current
ENV PATH /home/frogger/.sdkman/candidates/java/current/bin:/home/frogger/.sdkman/candidates/maven/current/bin:/home/frogger/.sdkman/candidates/gradle/current/bin:/usr/local/go/bin:/home/frogger/go/bin:${PATH}
ENV M2_HOME /home/frogger/.sdkman/candidates/maven/current

# Build time arguments
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true
ARG DEBIAN_FRONTEND=noninteractive

# Install prerequisites
RUN apt update && apt -yq upgrade
RUN apt install -yq zip unzip curl git uuid jq gettext python3-pip python3-venv apt-utils gnupg lsb-release

# Install npm
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt install -yq nodejs

# Install Yarn
RUN npm install -g yarn

# Configure Python
RUN ln -sf /usr/bin/pip3 /usr/bin/pip
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Pipenv and Poetry
RUN pip install pipenv poetry --quiet
# Override transitive pin from pipenv/poetry that pulled vulnerable cryptography 45.0.2
RUN pip install --upgrade 'cryptography>=46.0.3' --quiet

# Install Go
RUN curl -fL https://golang.org/dl/go1.26.3.linux-amd64.tar.gz | tar -zxC /usr/local

# Install .NET & NuGet
RUN curl -sL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
# Mono apt source — fetch the ASCII-armored key from the same host that serves the apt repo
# (CI allows download.mono-project.com but blocks keyserver.ubuntu.com), then dearmor to the
# binary OpenPGP format that signed-by= requires.
RUN curl -fsSL https://download.mono-project.com/repo/xamarin.gpg \
      | gpg --dearmor -o /usr/share/keyrings/mono-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN rm /etc/apt/sources.list.d/microsoft-prod.list
RUN apt update
RUN apt install -yq apt-transport-https dotnet-sdk-8.0 nuget msbuild mono-devel

# Install Java, Maven and Gradle
RUN curl -s "https://get.sdkman.io" | bash
RUN source "/home/frogger/.sdkman/bin/sdkman-init.sh" && sdk install java `sdk list java | grep -E "$JAVA_VERSION.*tem" | head -1 | awk '{print $NF}'` && java -version \
    && sdk install maven \
    && sdk install gradle 9.0.0 \
    && sdk flush archives

# Install Podman
RUN apt install -y ca-certificates
RUN apt update
RUN apt -yq install podman

# Install Docker client
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update
RUN apt install -y docker-ce docker-ce-cli containerd.io

# Clean up
RUN apt autoremove
RUN apt clean
