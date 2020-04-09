MULTIPLIER = 1 # this can be changed when tabs are used instead of spaces

def generate_template(description, options)

  template = File.read('./src/templates/template.tex')

  nodes = description[:states]
    .map(&:itself)
    .map { |(id, label)|
      "\\node[\\TMVMINTERNALNODE{#{id}}, state#{description[:start] == id ? ', initial' : ''}] (#{id}) {$#{label}$};"
    }

  edges = description[:transitions].map { |state, transitions|
    transitions.map { |t|
      id = state + "-" + t[:from_symbol]
      loop = t[:loop] ? ', loop above' : ''
      from = t[:from_id] && t[:from_symbol] == 'BLANK' ? '\\square' : t[:from_symbol]
      to   = t[:from_id] && t[:to_symbol]   == 'BLANK' ? '\\square' : t[:to_symbol]
      label = "#{from} | #{to} #{t[:direction] == 1 ? 'R' : t[:direction] == -1 ? 'L' : ''}"

      "(#{state}) edge[\\TMVMINTERNALEDGE{#{id}}#{loop}] node {$#{label}$} (#{t[:to_state]})"
    }
  }.flatten

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

  nodes_str = nodes.map { |node| " " * (state_col * MULTIPLIER) + node }
  edges_str = edges.map { |edge| " " * (edge_col  * MULTIPLIER) + edge }

  return template[0..state_pos] +
         (nodes_str.join("\n")) +
         template[state_pos..edge_pos] +
         (edges_str.join("\n")) +
         template[edge_pos..-1]

end
