$LOAD_PATH << File.join(File.dirname(__FILE__), 'vendor', 'graphy', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'graphy'
require 'graphy/dot'

require 'sketchup_support'
require 'graphy_support'
require 'cost_methods'
require 'pattern'
require 'graph_builder'

Math::Infinity = 1.0/0

include Unfolder::CostMethods

UI.menu("Plugins").add_item("Unfold (Normals)") do
  build_graph(Normals)
end

UI.menu("Plugins").add_item("Unfold (Normals respecting smooth)") do
  build_graph(Normals)
end

UI.menu("Plugins").add_item("Unfold (Uniform)") do
  build_graph(Uniform)
end

UI.menu("Plugins").add_item("Unfold (Centroids)") do
  build_graph(Centers)
end