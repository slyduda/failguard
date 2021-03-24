<h1 align="center">Failguard</h1>
<div align="center">
  <strong>PostgreSQL Fail Protection</strong>
</div>
<div align="center">
  A package that provisions and manages private PostgreSQL clusters for various cloud providers
</div>

<br />

<div align="center">
  <!-- Stability 
  <a href="https://nodejs.org/api/documentation.html#documentation_stability_index">
    <img src="https://img.shields.io/badge/stability-experimental-orange.svg?style=flat-square"
      alt="API stability" />
  </a>-->
  <!-- NPM version 
  <a href="https://npmjs.org/package/choo">
    <img src="https://img.shields.io/npm/v/choo.svg?style=flat-square"
      alt="NPM version" />
  </a>-->
  <!-- Build Status 
  <a href="https://travis-ci.org/choojs/choo">
    <img src="https://img.shields.io/travis/choojs/choo/master.svg?style=flat-square"
      alt="Build Status" />
  </a>-->
  <!-- Test Coverage 
  <a href="https://codecov.io/github/choojs/choo">
    <img src="https://img.shields.io/codecov/c/github/choojs/choo/master.svg?style=flat-square"
      alt="Test Coverage" />
  </a>-->
  <!-- Downloads
  <a href="https://npmjs.org/package/choo">
    <img src="https://img.shields.io/npm/dt/choo.svg?style=flat-square"
      alt="Download" />
  </a> -->
  <!-- Standard
  <a href="https://standardjs.com">
    <img src="https://img.shields.io/badge/code%20style-standard-brightgreen.svg?style=flat-square"
      alt="Standard" />
  </a> -->
</div>

<div align="center">
  <sub>Building free and open source to empower all. Built with ❤︎ by
  <a href="https://twitter.com/slyduda">Sylvester Duda, Gemify LLC </a> and
  <a href="https://github.com/slyduda/failguard/graphs/contributors">
    contributors.
  </a>
</div>

# Introduction
Failguard is built to automatically provision and manage private PostgreSQL clusters in Digital Ocean (more coming soon). This project allows others to spend as little time doing configuration, to spend more time ensuring that infrastructure meets best practices for handling production and volumes that could cause failures.

# Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [How It Works](#how-it-works)
- [Configurations](#configurations)
- [Custom Configurations](#custom-configurations)
- [Contributing](#contributing)
- [Maintainers](#maintainers)
- [License](#license)

## Requirements
- DigitalOcean Account
- Room for 5 Droplets
- Funds for 4 Droplets ($20 per month cheapest)
- Read & Write DigitalOcean API Key

[(Back to top)](#table-of-contents)
## Installation
Installation begins on a disposable Ubuntu server. Simple clone this repository and run with the following commands:

```sh
sudo git clone https://github.com/slyduda/failguard.git 
sudo chmod +x ./failguard/src/failguard.sh
bash failguard/src/failguard.sh
```

[(Back to top)](#table-of-contents)
## How it works
Four servers are deployed from the disposable server that acts as a build server for the source code of the main component behind Failguard, pgbackrest. The server types are as follows:

Droplet Name    | Host Name  | Description
------------ | ------------- | -------------
`[name]-db` | `pg-primary` | Primary DB instance that interacts with your apps.
`[name]-standby-[id]` | `pg-standby-[id]` | Standby DB in case your main goes offline.
`db-backup` | `pg-backup` | Dedicated server for storing encrypted backups.
`db-manager` | `pg-manager` | Dedicated DB management server with UI.

At a later point in time, this project will support instancing multiple standby servers along with, using additional clusters on the same backup server

[(Back to top)](#table-of-contents)
## Configurations
Currently, the only configuration that is enabled is the default with the following:

- Replication Streaming Server
- Dedicated Backup Server
- Encrypted Backups
- Dedicated Management Server
- Management Console UI (Coming Soon)

Later this package aims to allow:
- Single Server Local Backups
- Async Archiving
- Hot Standby

[(Back to top)](#table-of-contents)
## Custom Configurations
Custom Configurations will come soon with the above information in mind.

[(Back to top)](#table-of-contents)
## Contributing
Your contributions are always welcome! Please have a look at the [contribution guidelines](CONTRIBUTING.md) first. :tada:

[(Back to top)](#table-of-contents)
## Goals
The following must be included before the first release:
- Front-End Management Component
- Better Backend for Routing and Handling PITR (Point In Time Recovery)

[(Back to top)](#table-of-contents)
## Support


[(Back to top)](#table-of-contents)
## Maintainer(s)

[![Sylvester Duda](https://avatars1.githubusercontent.com/u/47706935?v=3&s=144)](https://github.com/slyduda)|[![Gemify](https://avatars1.githubusercontent.com/u/56842732?v=3&s=144)](https://github.com/gemifytech)
---|---
[Sylvester Duda](https://github.com/slyduda)|[Gemify](https://github.com/gemifytech)

[(Back to top)](#table-of-contents)
## License

 GNU General Public License v3.0 2021 - [Sylvester](https://github.com/slyduda/) & [Gemify](https://github.com/gemifytech). Please have a look at the [LICENSE.md](LICENSE.md) for more details.

[(Back to top)](#table-of-contents)