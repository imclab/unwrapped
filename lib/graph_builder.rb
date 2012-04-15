def build_tree(predecessors, graph)
  tree = Graphy::DirectedGraph.new
  
  # Hackety hack
  predecessors.each_pair do |node, predecessor|
    tree.add_edge!(predecessor, node, graph.edge_label(node, predecessor))
  end
  
  tree
end

def build_graph(cost_method)
  
  Sketchup.set_status_text "Building graph mesh", SB_PROMPT
  
  $graph = graph = Graphy::UndirectedGraph.new
  
  model = Sketchup.active_model
  selection = model.selection
  edges = selection.select{|s| s.class == Sketchup::Edge }
  faces = selection.select{|s| s.class == Sketchup::Face }
  
  # Bad code design alert
  mesh_layer = model.layers.add "Mesh"
  $mesh_layer = mesh_layer
  
  save = model.active_layer
  model.active_layer = mesh_layer
  
    mesh_group = model.entities.add_group
    
    faces.each do |face|      
      mesh_group.entities.add_faces_from_mesh face.mesh
    end
  
  model.active_layer = save

  edges = mesh_group.entities.select{|s| s.class == Sketchup::Edge }
  faces = mesh_group.entities.select{|s| s.class == Sketchup::Face }
  
  edges.each do |edge|
    connected_faces = edge.faces
    next if (connected_faces.size != 2) # not sure if this will ever happen
    
    # Bidirectional —— not sure if this is necessary
    graph.add_edge!(connected_faces.first, connected_faces.last, edge)
    graph.add_edge!(connected_faces.last, connected_faces.first, edge)
  end
  
  connected_components = graph.connected_components
  
  connected_components.each_with_index do |subgraph, index|
    
    Sketchup.set_status_text "Processing subgraph #{index+1} / #{connected_components.size}", SB_PROMPT
    
    costs, paths, delta = subgraph.floyd_warshall(cost_method)
    
    eccentricities = costs.map do |center, distances|
      # http://mathworld.wolfram.com/GraphEccentricity.html

      # For a disconnected graph, all vertices are defined
      # to have infinite eccentricity.
      next [center, Math::Infinity] if distances.size < (costs.size - 1)

      # Eccentricity of a graph vertex is the maximum graph
      # distance between v and any other vertex u  
      max = distances.max{|v, u| v[1] <=> u[1] }[1]
      
      [center, max]
    end
    
    # http://mathworld.wolfram.com/GraphCenter.html
    # Graph center is the vertex with minimum eccentricity
    center = eccentricities.min{|v, u| v[1] <=> u[1] }[0]
    
    root_face = center
    predecessors = paths[root_face]
    
    # F-W's predecessors chain is flaking out. Dijkstra's for now
    costs, predecessors = subgraph.dijkstras_algorithm(root_face, cost_method)
    
    tree = build_tree(predecessors, subgraph)
    
    $tree = tree
    # height = tree_height(tree, root_face)
    # color_tree(tree, root_face, 0, height)
    
    pattern = Pattern.new(subgraph, tree, root_face)
    
    pattern_layer = model.layers.add "Pattern"
    
    save = model.active_layer
    model.active_layer = pattern_layer

      pattern.build

    model.active_layer = save

    # Show the pattern layer
    model.active_layer = pattern_layer
    model.layers.reject{|l| l == pattern_layer}.each{|l| l.visible = false}
    
  end
  
  Sketchup.set_status_text "Processing completed", SB_PROMPT
  
end