class Pattern
  
  # assume it's already mesh-ized
  
  def initialize(graph, tree, root)
    @graph = graph
    @tree = tree
    @root = root
    @patches = []
    new_patch = {:faces => [], :source_incoming_edge => {}, :patch_incoming_edge => {}}
    @patches << new_patch
    calculate_pattern(root, new_patch)
  end
  
  def calculate_pattern(root, patch)
    #         C <--- C is calculated in the recursive method
    #       / \ 
    #     /    \  
    #   / root  \
    # A ~~~~~~~~~ B  <--- Incoming edge AB from root gets positioned on x-axis
    #
    
    # Vertices don't have position information. We make them into Point2d objects.
    points = root.vertices.map{|vertex| vertex.position}
    
    # Pick an edge
    source_point_a = points[0]
    source_point_b = points[1]
    
    # Place that edge on the x-axis
    distance = source_point_a.distance source_point_b
    patch_point_a = [0.0 ,0.0]
    patch_point_b = [distance, 0.0]
    
    # Save the initial edge for the recursive method
    patch[:source_incoming_edge][root] = [source_point_a, source_point_b]
    patch[:patch_incoming_edge][root] = [patch_point_a, patch_point_b]
    
    calculate_pattern_recursive(root, patch)
  end
  
  def find_ring_transform(seq, a, b)
    '''Finds the necessary ring_transform() arguments to place item A at
    the end, and item B at the beginning of the list.
    
    @type seq: list, or some other sequence supporting .index()
    @param seq: the sequence to transform
    @param A: item to place at the end
    @param B: item to place at the beginning
    '''
    n = seq.size
    ai = seq.index(a)
    bi = seq.index(b)
    if (bi-ai)%n == 1
      return bi, false
    elsif (bi-ai)%n == (n-1)
      return (bi+1)%n, true
    else
      raise "A and B not adjacent in ring"
    end
  end
  
  def ring_transform(seq, shift, flip=false, inverse=false)
    '''Returns a list containing the elements of seq, but shifted so the element
    seq[shift] is at [0], then optionally flipped.

    @type seq: sequence
    @param seq: the sequence to transform
    @type shift: integer
    @param shift: the number of spaces to shift the elements of seq
    @type flip: bool
    @param flip: Whether or not to reverse the order of the elements of seq
    @type inverse: bool
    @param inverse: perform the inverse transformation
    @rtype: list
    @return: transformed copy of seq
    '''
    l = seq.to_a
    n = l.size
    
    if inverse and not flip
      idx = (-shift)%n
    else
      idx = shift%n
    end
    
    l = l[idx..-1] + l[0...idx]
    l.reverse if flip
    
    return l
  end
  
  def solve_triangle(point_a, point_b, dist_ac, dist_bc)
    """C1, C2 = solve_triangle(point_a, point_b, dist_ac, dist_bc)
    Finds the third vertex of a triangle, given the coordinates of two
    vertices and the lengths of the sides adjacent to the third vertex.
    There are two solutions, C1 and C2. When looking from point_a to point_b, C1
    is to the left, and C2 is to the right.
    
    point_a, point_a, C1, C2 = tuples of (x,y) coordinates
    dist_ac, dist_bc = the lengths of the sides opposite A and B, respectively
    """
    
    da = dist_ac
    db = dist_bc
    
    xa, ya = point_a
    xb, yb = point_b
    da2 = da*da
    db2 = db*db
    dc2 = (xb-xa)**2 + (yb-ya)**2
    k1 = db2 + dc2 - da2
    k2 = (2*(da2*db2 + db2*dc2 + da2*dc2) - da2*da2 - db2*db2 - dc2*dc2)**(0.5)
    x1 = xa + (k1*(xb-xa) - k2*(yb - ya))/(2*dc2)
    x2 = xa + (k1*(xb-xa) + k2*(yb - ya))/(2*dc2)
    y1 = ya + (k1*(yb-ya) + k2*(xb - xa))/(2*dc2)
    y2 = ya + (k1*(yb-ya) - k2*(xb - xa))/(2*dc2)
    
    # if x1.nan? or y1.nan?
    #   
    #   $a = point_a
    #   $b = point_b
    #   $ac = dist_ac
    #   $bc = dist_bc
    #   raise "a:#{point_a}, b:#{point_b}, ac:#{dist_ac}, bc:#{dist_bc}, x:#{x1}, y:#{y1}"
    #   
    # end
    
    return [x1,y1], [x2, y2]
  end
  
  def in_box(segment, point)
    # This is stupid.
    
    # x-coords
    x_works = (segment[0][0] > point[0] && segment[1][0] < point[0]) || (segment[0][0] < point[0] && segment[1][0] > point[0])
    y_works = (segment[0][1] > point[1] && segment[1][1] < point[1]) || (segment[0][1] < point[1] && segment[1][1] > point[1])
    
    x_works && y_works
  end
  
  # Oh kill me now.
  def intersect?(triangle, lines)
    line1 = [triangle[0], triangle[2]]
    line2 = [triangle[1], triangle[2]]
    
    lines.any? do |line|
      $l1 = line1
      $l2 = line2
      $l = line
      $t = triangle
      
      int1 = Geom.intersect_line_line line, line1
      int2 = Geom.intersect_line_line line, line2
      
      intersected = false
      
      if(!int1.nil?)
        puts "#{line1.inspect} intersect #{line.inspect} at #{int1.inspect}"
        intersected = true if(in_box(line1, int1) && in_box(line, int1))
      end
      
      if (!int2.nil?)
        puts "#{line2.inspect} intersect #{line.inspect} at #{int2.inspect}"
        intersected = true if(in_box(line2, int2) && in_box(line, int2))
      end
      
      intersected
    end
  end
  
  def calculate_pattern_recursive(face, patch)
    #         C <--- We calculate point C
    #       / \ 
    #     /    \  
    #   / face  \
    # A ~~~~~~~~~ B  <--- Incoming edge AB is already calculated
    
    # Grab the initial edge's position in the 2D pattern and the 3D source object
    source_point_a, source_point_b = patch[:source_incoming_edge][face]
    patch_point_a, patch_point_b = patch[:patch_incoming_edge][face]
    
    # Vertices don't have position information. We make them into Point2d objects.
    source_points = face.vertices.map{|vertex| vertex.position}
    
    # Remove points A and B. They're already in the incoming edge
    remaining_vertices = source_points.reject!{|v| v == source_point_a or v == source_point_b} # Was more elegant but Array -() was acting up
    raise "Bug: Face has #{source_points.size} vertices when it should have three. Our 'sumptions are wrong." unless remaining_vertices.size == 1
    
    # Point C is the only one left
    source_point_c = remaining_vertices.first
    
    # Find point C in patch coordinates by solving the triangle
    dist_ac = source_point_a.distance source_point_c
    dist_bc = source_point_b.distance source_point_c
    # The solver produces two results because it's finding intersection of circles
    # We choose the first because it's above instead of below
    patch_point_c = solve_triangle(patch_point_a, patch_point_b, dist_bc, dist_ac).first
    
    triangle = [patch_point_a, patch_point_b, patch_point_c]
    
    if intersect?(triangle, patch[:patch_incoming_edge].values)
      # Make a new one
      puts "intersect!"
      new_patch = {:faces => [], :source_incoming_edge => {}, :patch_incoming_edge => {}}
      @patches << new_patch
      calculate_pattern(face, new_patch)
      return
    else
      # Add the new triangle to our flattened mesh
      patch[:faces] << triangle
    end
    
    # I can't think of a better way right now, so I'm emulating the ring tranform
    # method used in the python code. This makes it easier to ensure the connecting
    # edge is aligned CCW
    source_ordering = [source_point_b, source_point_c, source_point_a]
    patch_ordering = [patch_point_b, patch_point_c, patch_point_a]
    
    # Folds are connections between faces.
    # In our data structure they're graph edges with Sketchup edges as labels.
    folds = @tree.adjacent(face, :type => :edges)
    
    folds.each do |fold|
      connected_edge = fold.label
      connected_face = fold.target
      
      # These values serve a dual purpose: they let us order the vertices CCW
      # and map the source vertices to their patch vertices
      new_point_a_index = source_ordering.index(connected_edge.start.position)
      new_point_b_index = source_ordering.index(connected_edge.end.position)
      
      nverts = source_ordering.size
      
      # Since we always choose the first solution created by solve_triangle,
      # The vertices in the new edge must always be in CCW order. Otherwise
      # the next triangle will be built on the wrong side of the edge
      
      # I'm honestly a little fuzzy on this...
      if new_point_a_index == 0 and new_point_b_index == (nverts - 1)
        # edge in CCW order -> do nothing
      elsif new_point_a_index == (nverts-1) and new_point_b_index == 0
        # edge in CW order -> swap vertices
        new_point_a_index, new_point_b_index = new_point_b_index, new_point_a_index
      elsif new_point_a_index < new_point_b_index
        new_point_a_index, new_point_b_index = new_point_b_index, new_point_a_index
      end
        
      # Store initial edge that we want to calculate a triangle for
      patch[:source_incoming_edge][connected_face] = [source_ordering[new_point_a_index], source_ordering[new_point_b_index]]
      patch[:patch_incoming_edge][connected_face] = [patch_ordering[new_point_a_index], patch_ordering[new_point_b_index]]
      
      # Calculate the triangle and its connections
      calculate_pattern_recursive(connected_face, patch)
    end
    
  end
  
  def build
    @patches.each do |patch|
      $patch=patch
      
      pattern_group = Sketchup.active_model.entities.add_group
    
      patch[:faces].each do |triangle|
        pattern_group.entities.add_face *triangle
      end
    end
  end 
  
end