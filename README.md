# Kmod Puppet module

[![Build Status](https://github.com/voxpupuli/puppet-kmod/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-kmod/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-kmod/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-kmod/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/kmod.svg)](https://forge.puppetlabs.com/puppet/kmod)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/kmod.svg)](https://forge.puppetlabs.com/puppet/kmod)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/kmod.svg)](https://forge.puppetlabs.com/puppet/kmod)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/kmod.svg)](https://forge.puppetlabs.com/puppet/kmod)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-kmod)
[![Apache 2 License](https://img.shields.io/github/license/voxpupuli/puppet-kmod.svg)](LICENSE)
[![Donated by Camptocamp](https://img.shields.io/badge/donated%20by-camptocamp-fb7047.svg)](#transfer-notice)

## Description

This module provides definitions to manipulate modprobe.conf (5) stanzas:

 * kmod::alias
 * kmod::install
 * kmod::blacklist

It depends on Augeas with the modprobe lens.

## Usage

This module has five main defined types:

  * kmod::load
  * kmod::alias
  * kmod::option
  * kmod::install
  * kmod::blacklist


### kmod::load

Loads a module using modprobe and makes it persistent in `/etc/modules-load.d/<name>.conf`

```puppet
  kmod::load { 'mymodule': }
```

### kmod::alias

Adds an alias to modprobe.conf, by default `/etc/modprobe.d/<name>.conf` is assumed for a filename.

```puppet
  kmod::alias { 'bond0':
    source => 'bonding',
  }
```

Params:
* `source`: Name of the module to alias
* `aliasname`: Name of the alias (defaults to the resource title)
* `file`: File to write to (see above default)

### kmod::option

Adds an option to modprobe.conf

```puppet
  kmod::option { 'bond0 mode':
    module  => 'bond0',
    option  => 'mode',
    value   => '1',
  }

  kmod::option { 'bond0':
    option => 'mode',
    value  => '1',
  }
```

Params:
* `option`: Name of the parameter to add
* `value`: Value of the parameter
* `module`: Name of the module (if ommited, the resource title is used)
* `file`: File to write to (defaults to `/etc/modprobe.d/<module name>.conf`)

### kmod::blacklist

Manages modprobe blacklist entries. A blacklist entry only prevents module aliases from being
used, so an `install <module> /bin/false` entry is also added to the same file to prevent the
module from being loaded manually or as a dependency of another module.

```puppet
  kmod::blacklist { 'foo': }
```

Params:
* `file`: File to write to, defaults to `/etc/modprobe.d/blacklist.conf`

### kmod::install

Manage modprobe install entries

```puppet
   kmod::install { 'pcspkr': }
```

If you want to ensure that module can't be loaded at all you can do the following:
```puppet
   kmod::install { 'dccp': command => '/bin/false' }
```

Params:
* `file`: File to write to (defaults to `/etc/modprobe.d/<module name>.conf`)
* `command`: (optional) command associated with the install, defaults to `/bin/true`

## Using the module with hiera
The module makes available lists for every defined type that will create those
defined types if defined as class parameters. The parameters are:
* kmod::list_of_blacklists:
* kmod::list_of_aliases:
* kmod::list_of_installs:
* kmod::list_of_loads:
* kmod::list_of_options:

Example usage:
```
---
kmod::list_of_blacklists:
  'foo01': {}
  'foo02': {}
  'foo03': {}
kmod::list_of_aliases:
  'foo01':
    source: 'squashfs'
    aliasname: 'squash01'
  'foo02':
    source: 'squashfs'
    aliasname: 'squash02'
kmod::list_of_installs:
  'dccp':
    command: '/bin/false'
  'blah':
    command: '/bin/true'
kmod::list_of_loads:
  'cramfs': {}
  'vfat': {}
kmod::list_of_options:
  'bond0 mode':
    module: 'bond0'
    option: 'mode'
    value: '1'
  'bond0':
    option: 'mode'
    value: '1'
```

## Facts

### kmods

A hash of the loaded kernel modules that are declared by puppet via
`kmod::load`, keyed by module name. Each entry lists the module parameters
readable from sysfs and the modules using it:

```
kmods => {
  br_netfilter => {
    parameters => {},
    used_by => ['nf_conntrack']
  },
  overlay => {
    parameters => {
      check_copy_up => 'N',
      redirect_dir => 'Y'
    },
    used_by => []
  }
}
```

Only modules listed in `/etc/modules-load.d/*.conf` files written by
`kmod::load` are considered. A declared module that is not currently loaded is
left out. Module names use the kernel spelling, so `kmod::load { 'br-netfilter': }`
shows up as `br_netfilter`.

Earlier releases reported every loaded module from `/sys/module` regardless of
how it was loaded. Code that looked up modules loaded by the initramfs, a
container runtime or anything else outside `kmod::load` must no longer rely on
this fact.

## Contributing

Please report bugs and feature request using [GitHub issue
tracker](https://github.com/camptocamp/puppet-kmod/issues).

For pull requests, it is very much appreciated to check your Puppet manifest
with [puppet-lint](https://github.com/camptocamp/puppet-kmod/issues) to follow the recommended Puppet style guidelines from the
[Puppet Labs style guide](http://docs.puppetlabs.com/guides/style_guide.html).


## Transfer Notice

This plugin was originally authored by [Camptocamp](http://www.camptocamp.com).
The maintainer preferred that Puppet Community take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here instead of Camptocamp.

Previously: https://github.com/camptocamp/puppet-kmod
