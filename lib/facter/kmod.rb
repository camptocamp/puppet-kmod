Facter.add(:kmods) do
  confine :kernel => :linux
  confine File.exists?('/sys/module')

  kmod = {}

  setcode do
    Dir.foreach('/sys/module') do |directory|
      next if directory == '.' or directory == '..'

      kmod[directory] = {
        'parameters' => {},
        'used_by' => [],
      }

      if File.directory?("/sys/module/#{directory}/parameters")
        begin
          Dir.foreach("/sys/module/#{directory}/parameters") do |param|
            next if param == '.' or param == '..'
            kmod[directory]['parameters'][param] = File.read("/sys/module/#{directory}/parameters/#{param}").chomp
          end
        rescue => e
          Facter.warn(e)
        end
      end

      if File.directory?("/sys/module/#{directory}/holders")
        begin
          Dir.foreach("/sys/module/#{directory}/holders") do |used|
            next if used == '.' or used == '..'
            kmod[directory]['used_by'] << used
          end
        rescue => e
          Facter.warn(e)
        end
      end

    end

    kmod
  end
end
