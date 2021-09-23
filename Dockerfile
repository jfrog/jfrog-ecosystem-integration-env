FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]
RUN useradd -ms /bin/bash frogger
WORKDIR /home/frogger

# Environment variables
ENV HOME /home/frogger
ENV JAVA_HOME /home/frogger/.sdkman/candidates/java/current
ENV PATH /home/frogger/.sdkman/candidates/java/current/bin:/home/frogger/.sdkman/candidates/maven/current/bin:/home/frogger/.sdkman/candidates/gradle/current/bin:/usr/local/go/bin:${PATH}
ENV M2_HOME /home/frogger/.sdkman/candidates/maven/current

# Build time arguments
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true
ARG DEBIAN_FRONTEND=noninteractive

# Install prerequisites
RUN apt update
RUN apt install -yq zip unzip curl git uuid jq gettext python3-pip python3-venv nodejs npm

# Configure Python
RUN ln -sf /usr/bin/pip3 /usr/bin/pip
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Go
RUN curl -fL https://golang.org/dl/go1.16.8.linux-amd64.tar.gz | tar -zxC /usr/local

# Install .NET & NuGet
RUN curl -sL https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt update
RUN apt install -yq apt-transport-https dotnet-sdk-2.1 dotnet-sdk-3.1 nuget msbuild mono-devel

# Install Java, Maven and Gradle
RUN curl -s "https://get.sdkman.io" | bash
RUN source "/home/frogger/.sdkman/bin/sdkman-init.sh" && sdk install java `sdk list java | grep -E "11.*hs-adpt" | head -1 | awk '{print $NF}'` && java -version \
    && sdk install maven \
    && sdk install gradle \
    && sdk flush archives

# Install podman
RUN echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
RUN curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | apt-key add -
RUN apt update
RUN apt -yq install podman

# Upgrade npm
RUN npm config set prefix /usr
RUN npm install -g --force npm

# Install Yarn
RUN npm install -g yarn

# Clean up
RUN apt autoremove
RUN apt clean
