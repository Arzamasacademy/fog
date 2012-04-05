module Fog
  module Compute
    class Libvirt
      class Real
        def list_domains(filter = { })
          data=[]

          if filter.has_key?(:uuid)
            data << client.lookup_domain_by_uuid(filter[:uuid])
          elsif filter.has_key?(:name)
            data << client.lookup_domain_by_name(filter[:name])
          else
            client.list_defined_domains.each { |name| data << client.lookup_domain_by_name(name) } unless filter[:defined] == false
            client.list_domains.each { |id| data << client.lookup_domain_by_id(id) } unless filter[:active] == false
          end
          data.compact.map { |d| domain_to_attributes d }
        end

        private

        def vnc_port xml
          xml_element(xml, "domain/devices/graphics[@type='vnc']", "port")
        rescue => e
          # we might be using SPICE display, or no VNC display at all
          nil
        end

        def domain_volumes xml
          xml_elements(xml, "domain/devices/disk/source", "file")
        end

        def boot_order xml
          xml_elements(xml, "domain/os/boot", "dev")
        end

        def domain_interfaces xml
          ifs = xml_elements(xml, "domain/devices/interface")
          ifs.map { |i|
            nics.new({
              :type    => i['type'],
              :mac     => (i/'mac').first[:address],
              :network => ((i/'source').first[:network] rescue nil),
              :bridge  => ((i/'source').first[:bridge] rescue nil),
              :model   => ((i/'model').first[:type] rescue nil),
            }.reject{|k,v| v.nil?})
          }
        end

        def domain_to_attributes(dom)
          states= %w(nostate running blocked paused shutting-down shutoff crashed)
          {
            :id              => dom.uuid,
            :uuid            => dom.uuid,
            :name            => dom.name,
            :max_memory_size => dom.info.max_mem,
            :cputime         => dom.info.cpu_time,
            :memory_size     => dom.info.memory,
            :vcpus           => dom.info.nr_virt_cpu,
            :autostart       => dom.autostart?,
            :os_type         => dom.os_type,
            :active          => dom.active?,
            :vnc_port        => vnc_port(dom.xml_desc),
            :boot_order      => boot_order(dom.xml_desc),
            :nics            => domain_interfaces(dom.xml_desc),
            :volumes_path    => domain_volumes(dom.xml_desc),
            :state           => states[dom.info.state]
          }
        end

      end

      class Mock
        def list_vms(filter = { })

        end
      end
    end
  end
end