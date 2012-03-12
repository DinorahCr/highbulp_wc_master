class Pathfinder
	include ActiveModel::Validations

	attr_accessor :source, :destination, :all_pairs_distances

	def initialize(source=0, destination=0)
		@source = source
		@destination = destination
	end

	# Different types of generations (src/dest, all-pairs, etc)
	def path_from_src_to_dest(graph, src=0, dest=0)
		# Update source and destination
		@source, @destination = src, dest

		# Check if source and destination are 0
		# if so return empty path
		if @source == 0 and @destination == 0
			return []
		end

		# Generate a connections hash based on graph edges
		outgoing = Hash.new()
		nodes = graph.nodes.keys
		result = Array.new()

		graph.nodes.keys.each {|key| outgoing[key] = Hash.new() }
		graph.edges.each do |edge|
			# Is it possible for any two issues to have multiple links
			# between them?
			outgoing[edge.a.id][edge.b.id] = edge		
		end

		# If an edge already exists in the graph from source to destination
		if outgoing[@source].has_key?(@destination)
			result.push(outgoing[@source][@destination].id)
			return result
		end
			
		# Compute all paths from source
		paths_tracer, paths_distances, relationships_on_paths = compute_paths_from_source(outgoing, nodes)
		
		# Find the shortest path through the graph between source and destination
		if destination != 0
			return trace_path_src_to_dest(outgoing, paths_tracer)
		end

		return relationships_on_paths
	end

	def compute_paths_from_source(edges, nodes)
		# Inputs: outgoing edges of each vertex, vertex array
		
		# Initializations		
		inf = 1/0.0	
		distance = Hash.new()
		previous = Hash.new()

		nodes.each do |i|
			distance[i] = inf
			previous[i] = -1
		end

		distance[@source] = 0
		queue = nodes.compact

		# Find shortest paths
		while (queue.length > 0)
			# Check for accessible vertices
			u = nil
			queue.each do |min|
				if (not u) or (distance[min] and distance[min] < distance[u])
					u = min
				end
			end
			
			if (distance[u] == inf)
				break
			end

			# Check neighbors
			queue = queue - [u]
			edges[u].keys.each do |v|
				alt = distance[u] + 1 # Placeholder
				if alt < distance[v]
					distance[v] = alt
					previous[v] = u
				end
			end
		end

		return previous, distance, get_relationships_by_tracer(previous, edges)

	end

	def get_relationships_by_tracer(tracer, edges)
		# This method walks through a tracer (a list of "previous" nodes) by key,value,
		# adding the relationship id of each to an array which is then returned.
		# tracer[child] = parent
		# On the paths from source to all of its destinations, some relationship parent->child exists.
	
		relationships = Array.new		
		tracer.each do |key, value|
			if value != -1
				relationships << edges[value][key].id
			end
		end

		return relationships
	end

	def trace_path_src_to_dest(edges, tracer)
		# Computes path from destination to source

		path = []
		current = @destination
		while tracer[current] != -1
			path << edges[ tracer[current] ][ current ].id
			current = tracer[current]
		end

		# Check for source...

		return path
	end

	def compute_all_pairs_paths(e, v)
		distances = Hash.new()

		v.each do |node|
			@source = node
			tmp1, distances[node], tmp2 = compute_paths_from_source(e, v)		
		end	

		return distances	
	end
end
