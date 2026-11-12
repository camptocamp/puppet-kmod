# frozen_string_literal: true

require_relative 'util/kmod'

# @summary Hash of the loaded kernel modules declared by puppet via kmod::load,
#   keyed by module name, with their parameters and the modules using them.
#
# Only modules listed in /etc/modules-load.d files written by kmod::load are
# considered; a declared module that is not loaded is left out. Module names
# use the kernel spelling (underscores, not dashes).
Facter.add(:kmods) do
  confine kernel: :linux

  setcode do
    if File.directory?(Facter::Util::Kmod::SYS_MODULE)
      Facter::Util::Kmod.declared_modules.each_with_object({}) do |name, kmods|
        config = Facter::Util::Kmod.module_config(name)
        kmods[name] = config if config
      end
    else
      Facter.debug('/sys/module is not found. skipping.')
      nil
    end
  end
end
