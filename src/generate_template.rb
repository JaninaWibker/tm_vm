MULTIPLIER = 1 # this can be changed when tabs are used instead of spaces

def merge_similar(state, transitions) # returns an array of groups, each group consists of similar transitions

  known = {}

  transitions
    .map { |t| [t[:to_state] + "_" + t[:direction].to_s, t] }
    .each { |(id, t)|
      if known.key? id
        known[id].push(t)
      else
        known[id] = [t]
      end
  }

  return known.values

end

def generate_template(description, options)

  template = File.read('./src/templates/template.tex')

  nodes = description[:states]
    .map(&:itself)
    .map { |(id, label)|
      "\\node[\\TMVMNODE{#{id}}, state#{description[:start] == id ? ', initial' : ''}] (#{id}) {$#{label}$};"
    }

  edges = description[:transitions]
    .map { |state, transitions| [state, merge_similar(state, transitions)] }
    .map { |(state, groups)| groups.map { |g|
      from = []
      to   = []
      g.map { |t|
        from.push t[:from_id] && t[:from_symbol] == 'BLANK' ? '\\square' : t[:from_symbol]
        to.push   t[:to_id]   && t[:to_symbol]   == 'BLANK' ? '\\square' : t[:to_symbol]
      }
      symbols = from.map { |s|
        s == '\\square' ? 'BLANK' : (s.include?("'") ? ('"' + s + '"') : ("'" + s + "'"))
      }.join(", ")

      from_label = from.join(", ")
      to_label   = to.join(", ")
      loop = g[0][:loop] ? ', loop above' : ''
      direction  = g[0][:direction] == 1 ? 'R' : g[0][:direction] == -1 ? 'L' : ''

      label = "#{from_label} \\vert #{to_label} #{direction}"

      next "(#{state}) edge[\\TMVMEDGE{#{state}}{#{symbols}}#{loop}] node {$#{label}$} (#{g[0][:to_state]})"
    }
  }

  state_line  = 0
  state_col   = 0
  state_pos   = 0
  state_found = false
  edge_line   = 0
  edge_col    = 0
  edge_pos    = 0
  edge_found  = false

  template.each_line.with_index do |line, idx|
    col = line =~ /%\{STATES\}%/
    if col != nil
      state_line  = idx
      state_col   = col
      state_found = true
      state_pos += col + '%{STATES}%'.size
    elsif !state_found
      state_pos += line.size
    end

    col = line =~ /%\{EDGES\}%/
    if col != nil
      edge_line  = idx
      edge_col   = col
      edge_found = true
      edge_pos += col + '%{EDGES}%'.size
    elsif !edge_found
      edge_pos += line.size
    end
  end

  edges_str = edges.map { |edges|
    edges.map { |edge| " " * (edge_col * MULTIPLIER) + edge}.join("\n") + "\n"
  }

  nodes_str = nodes.map { |node| " " * (state_col * MULTIPLIER) + node }
  # edges_str = edges.map { |edge| " " * (edge_col  * MULTIPLIER) + edge }

  return template[0..state_pos] +
         (nodes_str.join("\n")) +
         template[state_pos..edge_pos] +
         (edges_str.join("\n")) +
         template[edge_pos..-1]

end
