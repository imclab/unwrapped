module Unfolder
  module CostMethods
    Random = lambda{rand*100}
    Uniform = lambda{1}
    Normals = lambda{|e| (e.source.normal - e.target.normal).length }
    NormalsWithSmooth = lambda{|e| e.label.smooth? ? -(1000/Normals.call(e)) : Normals.call(e) }
    Centers = lambda{|e| (e.source.centroid).distance(e.target.centroid) }
  end
end