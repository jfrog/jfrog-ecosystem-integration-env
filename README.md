[![Test](https://github.com/jfrog/jfrog-ecosystem-integration-env/actions/workflows/test.yml/badge.svg)](https://github.com/jfrog/jfrog-ecosystem-integration-env/actions/workflows/test.yml)
[![Latest Tag](https://badgen.net/github/tag/jfrog/jfrog-ecosystem-integration-env)](https://releases-docker.jfrog.io/artifactory/reg2/jfrog-ecosystem-integration-env/latest)

# JFrog Ecosystem Integration Environment

JFrog Ecosystem integration environment is a Docker image containing all the tools JFrog CLI integrates with and supports.

## Using the Docker Image

This Docker image can be pulled from `releases.jfrog.io` by running the following command:

```
docker pull releases-docker.jfrog.io/jfrog-ecosystem-integration-env:<tag>
```

Running the docker image:

```
docker run -it releases-docker.jfrog.io/jfrog-ecosystem-integration-env
```

## Supported tools

The image is using `apt` and `sdkman` to download the build tools. Note: In the `:latest` tag, the tools versions may change.

Operating system: ![GitHub](https://img.shields.io/static/v1?label=Ubuntu&message=+22.04+LTS&color=blue&style=for-the-badge&logo=ubuntu)

|  Tool   | Current version |  Package name  |                      Source                      |
| :-----: |:---------------:| :------------: | :----------------------------------------------: |
|  .NET   |       6.0       | dotnet-sdk-6.0 | https://packages.microsoft.com/ubuntu/22.04/prod |
|  cURL   |     7.81.0      |      curl      |                  Ubuntu archive                  |
| Docker  |     23.0.2      |     docker     |     https://download.docker.com/linux/ubuntu     |
|   Go    |     1.22.x      |   golang-go    |              https://golang.org/dl               |
| Gradle  |      8.6.x      |     gradle     |          https://sdkman.io/sdks#gradle           |
|   JDK   |     11.0.x      |      tem       |            https://sdkman.io/jdks#tem            |
|   jq    |      1.6.x      |       jq       |                  Ubuntu archive                  |
|  Maven  |      3.9.x      |     maven      |           https://sdkman.io/sdks#maven           |
|  Mono   |    6.12.0.x     |   mono-devel   |  https://download.mono-project.com/repo/ubuntu   |
| MSBuild |     16.10.x     |    msbuild     |  https://download.mono-project.com/repo/ubuntu   |
| NodeJS  |     18.19.x     |     nodejs     |               npm public registry                |
|   npm   |     10.2.x      |      npm       |               npm public registry                |
|  NuGet  |      6.6.x      |     nuget      |  https://download.mono-project.com/repo/ubuntu   |
|   Pip   |     22.0.x      |  python3-pip   |                  Ubuntu archive                  |
| Pipenv  |    2023.12.x    |     pipenv     |                  Ubuntu archive                  |
| Podman  |      3.4.x      |     podman     |    https://download.opensuse.org/repositories    |
| Poetry  |      1.7.x      |     poetry     |                https://pypi.org/                 |
| Python  |     3.10.x      |  python3-pip   |                  Ubuntu archive                  |
|  Yarn   |     1.22.x      |      yarn      |               npm public registry                |
