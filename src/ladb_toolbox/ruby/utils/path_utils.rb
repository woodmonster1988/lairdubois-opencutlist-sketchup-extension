require_relative 'model_utils'

module Ladb
  module Toolbox
    class PathUtils

      SEPARATOR = '>'

      # -- Serialization --

      def self.serialize_path(path)  # path is Array<ComponentInstance>
        return nil if path.nil?
        entity_ids = []
        path.each { |entity|
          entity_ids.push(entity.entityID)
        }
        entity_ids.join(SEPARATOR)
      end

      def self.unserialize_path(serialized_path)
        path = []
        entity_ids = serialized_path.split(SEPARATOR)
        entity_ids.each { |entity_id|
          entity = ModelUtils::find_entity_by_id(Sketchup.active_model, entity_id.to_i)
          if entity
            path.push(entity)
          else
            return nil
          end
        }
        path
      end

      # -- Manipulation --

      def self.get_leaf_entity(serialized_path)
        ModelUtils::find_entity_by_id(Sketchup.active_model, serialized_path.split(SEPARATOR).last.to_i)
      end

      # -- Geom --

      def self.get_transformation(path)
        transformation = Geom::Transformation.new
        path.each { |entity|
          transformation *= entity.transformation
        }
        transformation
      end

    end
  end
end
