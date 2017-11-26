[![build](https://ci.appveyor.com/api/projects/status/github/admiringworm/wormies-au-helpers?svg=true)](https://ci.appveyor.com/project/admiringWorm/wormies-au-helpers) [![license](https://img.shields.io/github/license/AdmiringWorm/Wormies-AU-Helpers.svg)](https://github.com/AdmiringWorm/Wormies-AU-Helpers/blob/master/LICENSE)

# Chocolatey Automatic Package Updater Helper Module

This PowerShell module implements functions that can be used to make maintaining packages with AU even easier.

To Learn more about AU, please refer to their relevant [documentation](https://github.com/majkinetor/au/wiki)

## Features
- Ability to push out fix versions for both 4-part versions and pre-release versions by calling a single function.
- Ability to easily get the url that is being redirected to.

## Installation

Wormies-AU-Helpers requires a minimally PowerShell version 3: `$host.Version -ge '3.0'`.

To install it, use one of the following methods:
- PowerShell Gallery: [`Install-Module wormies-au-helpers`](https://www.powershellgallery.com/packages/Wormies-AU-Helpers)
- Chocolatey: [`choco install wormies-au-helpers`](https://chocolatey.org/packages/wormies-au-helpers)
- [Download](https://com/majkinetor/au/releases/latest) latest 7z package, or latest build [artifact](https://ci.appveyor.com/project/admiringworm/wormies-au-helpers/build/artifacts)
