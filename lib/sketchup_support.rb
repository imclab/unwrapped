module Geom
  
  class PolygonMesh
    alias :<< :add_point
  end
  
end

module Sketchup
  
  class Entities
    NO_SOFTEN_NO_SMOOTH = 0
  end
  
  class Model
    def in_layer(layer)
      save = self.active_layer
      
      self.active_layer = layer
      yield
      
      self.active_layer = save
    end
  end
  
  # class Entity
  #   def erase!
  #     parent.erase_entities self
  #   end
  # end
  
  class Face
    def centroid
    # [ sum(x) + sum(y) + sum(z) ] / 3
    # http://en.wikipedia.org/wiki/Centroid
      
      points = vertices.map{|f|f.position}
      # for some reason I can't add points without making one an array first
      sum = points.inject(Geom::Point3d.new) {|sum,p| sum + p.to_a}
      
      # No scalar multiplication available, so we scale 
      scalar_division = Geom::Transformation.scaling 1.0/points.size
      centroid = sum.transform scalar_division
      
      centroid
    end
  end
  
end