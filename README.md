[![Build status](https://img.shields.io/appveyor/ci/AdmiringWorm/Wormies-AU-Helpers.svg?style=plastic&logo=appveyor)](https://ci.appveyor.com/project/AdmiringWorm/wormies-au-helpers) [![Code Coverage](https://img.shields.io/codecov/c/github/WormieCorp/Wormies-AU-Helpers/develop.svg?style=plastic)](https://codecov.io/gh/WormieCorp/Wormies-AU-Helpers/branch/develop) [![license](https://img.shields.io/github/license/WormieCorp/Wormies-AU-Helpers.svg?style=plastic)](https://github.com/WormieCorp/Wormies-AU-Helpers/blob/master/LICENSE)
[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors)

TODO: This is added just as a test
# Chocolatey Automatic Package Updater Helper Module

This PowerShell module implements functions that can be used to make maintaining packages with AU even easier.

To Learn more about AU, please refer to their relevant [documentation](https://github.com/majkinetor/au/wiki)

## Features
- Ability to push out fix versions for both 4-part versions and pre-release versions by calling a single function.
- Ability to easily get the url that is being redirected to.
- Ability to update either a single or multiple metadata elements

Please read our documentation for an overall view of the functions available:
https://wormiecorp.github.io/Wormies-AU-Helpers/docs/

## Installation

Wormies-AU-Helpers requires a minimally PowerShell version 3: `$host.Version -ge '3.0'`.

To install it, use one of the following methods:
- [![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Wormies-AU-Helpers.svg?style=plastic)](https://www.powershellgallery.com/packages/Wormies-AU-Helpers): [`Install-Module wormies-au-helpers`]
- [![Chocolatey](https://img.shields.io/chocolatey/v/wormies-au-helpers.svg?style=plastic)](https://chocolatey.org/packages/wormies-au-helpers): [`choco install wormies-au-helpers`]
- [![MyGet](https://img.shields.io/myget/wormie-nugets/vpre/wormies-au-helpers.svg?style=plastic&label=MyGet)](https://www.myget.org/feed/wormie-nugets/package/nuget/wormies-au-helpers): [`choco install wormies-au-helpers --source https://www.myget.org/F/wormie-nugets --pre`]
- Download the 7z archive from the latest [![GitHub Release](https://img.shields.io/github/release/WormieCorp/Wormies-AU-Helpers.svg?style=plastic&label=GitHub%20Release)](https://github.com/WormieCorp/Wormies-AU-Helpers/releases/latest), or latest appveyor build [artifact](https://ci.appveyor.com/project/admiringworm/wormies-au-helpers/build/artifacts)

## Contributors

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table><tr><td align="center"><a href="https://github.com/AdmiringWorm"><img src="https://avatars3.githubusercontent.com/u/1474648?v=4" width="100px;" alt="Kim J. Nordmo"/><br /><sub><b>Kim J. Nordmo</b></sub></a><br /><a href="#maintenance-AdmiringWorm" title="Maintenance">🚧</a></td><td align="center"><a href="https://github.com/RedBaron2"><img src="https://avatars1.githubusercontent.com/u/1191271?v=4" width="100px;" alt="RB"/><br /><sub><b>RB</b></sub></a><br /><a href="https://github.com/WormieCorp/Wormies-AU-Helpers/commits?author=RedBaron2" title="Code">💻</a> <a href="https://github.com/WormieCorp/Wormies-AU-Helpers/issues?q=author%3ARedBaron2+label%3Abug" title="Bug reports">🐛</a></td></tr></table>
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
