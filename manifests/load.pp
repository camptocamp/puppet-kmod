# == Definition: kmod::load
#
# Manage a kernel module in /etc/modules.
#
# Parameters:
# - *ensure*: present/absent;
# - *file*: optionally, set the file where the stanza is written.
#
# Example usage:
#
#   kmod::load { 'sha256': }
#
define kmod::load (
  $ensure = 'present',
  $file   = '/etc/modules',
) {

  case $ensure {
    'present': {
      $changes = "clear '${name}'"

      exec { "modprobe ${name}":
        path   => '/bin:/sbin:/usr/bin:/usr/sbin',
        unless => "egrep -q '^${name} ' /proc/modules",
      }
    }
    'absent': {
      $changes = "rm '${name}'"

      exec { "modprobe -r ${name}":
        path   => '/bin:/sbin:/usr/bin:/usr/sbin',
        onlyif => "egrep -q '^${name} ' /proc/modules",
      }
    }
    default: {
      fail("unknown ensure value ${ensure}")
    }
  }

  case $::osfamily {
    'Debian': {
      augeas {"Manage ${name} in ${file}":
        incl    => $file,
        lens    => 'Modules.lns',
        changes => $changes,
      }
    }
    'RedHat': {
      file { "/etc/sysconfig/modules/${name}.modules":
        ensure  => $ensure,
        mode    => '0755',
        content => template('kmod/redhat.modprobe.erb'),
      }
    }
    default: {
      fail("Unknown OS family ${::osfamily}")
    }
  }
}
