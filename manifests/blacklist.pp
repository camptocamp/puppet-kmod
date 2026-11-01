# @summary Set a kernel module as blacklisted and prevent it from being loaded.
#
# Besides the `blacklist` entry, an `install <module> /bin/false` entry is added
# so the module cannot be loaded manually or as a dependency of another module.
#
# @param ensure State of the setting
# @param file File to manage
#
# @example
#   kmod::blacklist { 'pcspkr': }
define kmod::blacklist (
  Enum['present', 'absent'] $ensure = 'present',
  Stdlib::Unixpath          $file   = '/etc/modprobe.d/blacklist.conf',
) {
  include kmod

  kmod::setting { "kmod::blacklist ${title}":
    ensure   => $ensure,
    module   => $name,
    file     => $file,
    category => 'blacklist',
  }

  kmod::setting { "kmod::blacklist ${title} install":
    ensure   => $ensure,
    module   => $name,
    file     => $file,
    category => 'install',
    option   => 'command',
    value    => '/bin/false',
  }
}
