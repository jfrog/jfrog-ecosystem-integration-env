# JFrog Ecosystem Integration Environment

JFrog Ecosystem integration environment is a Docker image containing all the tools JFrog CLI integrates with and supports.

## Supported tools

The image is using `apt` and `sdkman` to download the build tools. Note: In the `:latest` tag, the tools versions may change.

Operating system: Ubuntu 20.04.

|  Tool   | Current version |  Package name  |                      Source                      |
| :-----: | :-------------: | :------------: | :----------------------------------------------: |
|  .NET   |      3.1.x      | dotnet-sdk-3.1 | https://packages.microsoft.com/ubuntu/20.04/prod |
|  cURL   |     7.68.x      |      curl      |                  Ubuntu archive                  |
|   Go    |     1.14.x      |  golang-1.14   |                  Ubuntu archive                  |
| Gradle  |      6.5.x      |     gradle     |          https://sdkman.io/sdks#gradle           |
|   JDK   |     11.0.x      | 11.0.7.hs-adpt |       https://sdkman.io/jdks#AdoptOpenJDK        |
|   jq    |      1.6.x      |       jq       |                  Ubuntu archive                  |
| MSBuild |    16.5.x-ci    |    msbuild     |  https://download.mono-project.com/repo/ubuntu   |
| NodeJS  |      10.x       |     nodejs     |                  Ubuntu archive                  |
|  Mono   |     6.8.0.x     |   mono-devel   |  https://download.mono-project.com/repo/ubuntu   |
|  Maven  |      3.6.x      |     maven      |           https://sdkman.io/sdks#maven           |
|   npm   |     6.14.x      |      npm       |                  Ubuntu archive                  |
|  NuGet  |     5.5.0.x     |     nuget      |  https://download.mono-project.com/repo/ubuntu   |
|   Pip   |     20.0.x      |  python3-pip   |                  Ubuntu archive                  |
| Python  |      3.8.x      |  python3-pip   |                  Ubuntu archive                  |
