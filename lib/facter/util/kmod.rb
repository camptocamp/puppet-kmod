# frozen_string_literal: true

module Facter
  module Util
    # Helpers for the kmods fact.
    module Kmod
      MODULES_LOAD_D = '/etc/modules-load.d'
      SYS_MODULE = '/sys/module'
      # Header written by kmod::load (see manifests/load.pp).
      MANAGED_HEADER = '# This file is managed by the puppet kmod module.'

      module_function

      # Names of the modules listed in modules-load.d files written by
      # kmod::load. Names are normalised to the form the kernel uses in
      # /sys/module, i.e. dashes become underscores.
      #
      # @param modules_load_d [String] directory holding the *.conf files
      # @return [Array<String>] unique module names
      def declared_modules(modules_load_d = MODULES_LOAD_D)
        names = Dir.glob(File.join(modules_load_d, '*.conf')).flat_map do |conf|
          lines = File.readlines(conf, chomp: true).map(&:strip)
          next [] unless lines.first == MANAGED_HEADER

          lines.reject { |line| line.empty? || line.start_with?('#', ';') }
        end
        names.map { |name| name.tr('-', '_') }.uniq
      end

      # Parameters and holders of a loaded module.
      #
      # @param name [String] kernel module name
      # @param sys_module [String] sysfs module directory
      # @return [Hash, nil] nil when the module is not loaded
      def module_config(name, sys_module = SYS_MODULE)
        dir = File.join(sys_module, name)
        return nil unless File.directory?(dir)

        {
          'parameters' => parameters(File.join(dir, 'parameters')),
          'used_by' => entries(File.join(dir, 'holders')),
        }
      end

      # @api private
      def parameters(dir)
        entries(dir).each_with_object({}) do |param, params|
          path = File.join(dir, param)
          next unless File.readable?(path)

          begin
            params[param] = File.read(path).chomp.delete("\u0000")
          rescue StandardError
            # some kernel parameters are write only
            # even though they have the read bit set
            # so just ignore read errors
            nil
          end
        end
      end

      # @api private
      def entries(dir)
        return [] unless File.directory?(dir)

        Dir.children(dir).sort
      end
    end
  end
end
