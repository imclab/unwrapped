module Graphy
  
  class UndirectedGraph
      
      include Graphy::DirectedGraph::Distance
      
      def floyd_warshall(weight=nil, zero=0)
        c     = Hash.new {|h,k| h[k] = Hash.new}
        path  = Hash.new {|h,k| h[k] = Hash.new}
        delta = Hash.new {|h,k| h[k] = 0}
        edges.each do |e| 
          delta[e.source] += 1
          delta[e.target] -= 1
          path[e.source][e.target] = e.target      
          c[e.source][e.target] = cost(e, weight)
          c[e.target][e.source] = cost(e, weight)
        end
        vertices.each do |k|
          vertices.each do |i|
            if c[i][k]
              vertices.each do |j|
                if c[k][j] && 
                    (c[i][j].nil? or c[i][j] > (c[i][k] + c[k][j]))
                  path[i][j] = path[i][k]
                  c[i][j] = c[i][k] + c[k][j]
                  return nil if i == j and c[i][j] < zero
                end
              end
            end  
          end
        end
        [c, path, delta]
      end # floyd_warshall

      def connected_components
        components = []
        current_component = nil
        add_edge_to_component = Proc.new { |edge| current_component << edge }
        start_new_component = Proc.new{ current_component = []; components << current_component }
        bfs :tree_edge => add_edge_to_component, :root_vertex => start_new_component
  
        components.map {|c| UndirectedGraph.new.add_edges!(*c) }
      end
    
  end
    
end