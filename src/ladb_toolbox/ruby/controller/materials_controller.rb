require 'pathname'
require 'securerandom'
require_relative 'controller'
require_relative '../model/material_attributes'

module Ladb
  module Toolbox
    class MaterialsController < Controller

      def initialize(plugin)
        super(plugin, 'materials')
      end

      def setup_commands()

        # Setup toolbox dialog actions
        @plugin.register_command("materials_list") do ||
          list_command
        end
        @plugin.register_command("materials_purge_unused") do ||
          purge_unused_command
        end
        @plugin.register_command("materials_update") do |material_data|
          update_command(material_data)
        end

      end

      private

      # -- Commands --

      def list_command()

        model = Sketchup.active_model
        materials = model.materials

        temp_dir = @plugin.temp_dir
        material_thumbnails_dir = File.join(temp_dir, 'material_thumbnails')
        unless Dir.exist?(material_thumbnails_dir)
          Dir.mkdir(material_thumbnails_dir)
        end

        data = {
            :errors => [],
            :warnings => [],
            :filename => Pathname.new(model.path).basename,
            :hardwood_material_count => 0,
            :plywood_material_count => 0,
            :unknow_material_count => 0,
            :materials => []
        }
        materials.each_with_index { |material, index|

          thumbnail_file = File.join(material_thumbnails_dir, "#{index}.png")
          material.write_thumbnail(thumbnail_file, 128)

          material_attributes = MaterialAttributes.new(material)

          data[:materials].push({
                                    :id => material.entityID,
                                    :name => material.name,
                                    :display_name => material.display_name,
                                    :thumbnail_file => thumbnail_file,
                                    :color => '#' + material.color.to_i.to_s(16),
                                    :attributes => {
                                        :type => material_attributes.type,
                                        :length_increase => material_attributes.length_increase,
                                        :width_increase => material_attributes.width_increase,
                                        :thickness_increase => material_attributes.thickness_increase,
                                        :std_thicknesses => material_attributes.std_thicknesses
                                    }
                                })

          case material_attributes.type
            when MaterialAttributes::TYPE_SOLID_WOOD
              data[:hardwood_material_count] += 1
            when MaterialAttributes::TYPE_SHEET_GOOD
              data[:plywood_material_count] += 1
            else
              data[:unknow_material_count] += 1
          end
        }

        # Errors
        if materials.count == 0
          data[:errors].push('tab.materials.error.no_materials')
        end

        # Sort materials by type ASC, display_name ASC
        data[:materials].sort_by! { |v| [v[:display_name]] }

        data
      end

      def purge_unused_command()

        materials = Sketchup.active_model.materials
        materials.purge_unused

      end

      def update_command(material_data)

        name = material_data['name']
        display_name = material_data['display_name']
        attributes = material_data['attributes']
        type = MaterialAttributes.valid_type(attributes['type'])
        length_increase = attributes['length_increase']
        width_increase = attributes['width_increase']
        thickness_increase = attributes['thickness_increase']
        std_thicknesses = attributes['std_thicknesses']

        # Fetch material
        model = Sketchup.active_model
        materials = model.materials
        material = materials[name]

        if material

          # Update properties
          material.name = display_name

          # Update attributes
          material_attributes = MaterialAttributes.new(material)
          material_attributes.type = type
          material_attributes.length_increase = length_increase
          material_attributes.width_increase = width_increase
          material_attributes.thickness_increase = thickness_increase
          material_attributes.std_thicknesses = std_thicknesses
          material_attributes.write_to_attributes

          # Set material as current
          materials.current = material

        end

      end

    end
  end
end