# JFrog CLI Integration Environment

JFrog CLI integration environment is a Docker image containing all build tools the JFrog CLI supports.

## Supported build tools

The image is using `apt` and `sdkman` to download the build tools. In the `:latest` tag, the versions may vary from time to time - please consider that.

Operating system: Ubuntu 20.04.

|  Tool   | Current version |  Package name  |                      Source                      |
| :-----: | :-------------: | :------------: | :----------------------------------------------: |
|   Go    |     1.14.x      |  golang-1.14   |                  Ubuntu archive                  |
| NodeJS  |      10.x       |     nodejs     |                  Ubuntu archive                  |
|   npm   |     6.14.x      |      npm       |                  Ubuntu archive                  |
| Python  |      3.8.x      |  python3-pip   |                  Ubuntu archive                  |
|   Pip   |     20.0.x      |  python3-pip   |                  Ubuntu archive                  |
|  .NET   |      3.1.x      | dotnet-sdk-3.1 | https://packages.microsoft.com/ubuntu/20.04/prod |
|  Mono   |     6.8.0.x     |   mono-devel   |  https://download.mono-project.com/repo/ubuntu   |
|  NuGet  |     5.5.0.x     |     nuget      |  https://download.mono-project.com/repo/ubuntu   |
| MSBuild |    16.5.x-ci    |    msbuild     |  https://download.mono-project.com/repo/ubuntu   |
|   JDK   |     11.0.x      | 11.0.7.hs-adpt |       https://sdkman.io/jdks#AdoptOpenJDK        |
|  Maven  |      3.6.x      |     maven      |           https://sdkman.io/sdks#maven           |
| Gradle  |      6.5.x      |     gradle     |          https://sdkman.io/sdks#gradle           |
