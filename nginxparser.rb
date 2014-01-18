class NginxParser
  def initialize(path)
    unless File.exists?(path)
      return false
    end
    f = File.open(path)
    @lines = f.readlines
  end

  def parse
    lines = @lines
    upstream_blocks = Hash.new
    server_blocks = Hash.new
    ptr = 0
    while (ptr < lines.count) do
      line = lines[ptr]
      if line.match(/upstream ([a-zA-Z]+) {/)
        upstr_name = line.match(/upstream ([a-zA-Z]+) {/)[1]
        servers = []
        ptr += 1
        while (lines[ptr].split(" ")[0] == "server") do
          line = lines[ptr].split(" ")
          address = line[1]
          parameters = line[2..-1]
          parameters.map! do |e| 
            e = e.gsub(/;/, '')
            e = e.split("=")
          end
          servers.push({:address => address, :parameters => parameters})
          ptr += 1
        end
        upstream_blocks[upstr_name] = servers
      end
      if line.include?("server") and line.include?("{")
        ptr += 1
        items = []
        while (lines[ptr].split(" ")[0] != "}") do
          block = []
          line = lines[ptr].split(" ")
          if line[0] == "location"
            ptr += 1
            location_items = []
            location_name = line.join(" ")
            while (lines[ptr].split(" ")[0] != "}") do
              line = lines[ptr].split(" ")
              key = line[0]
              values = line[1..-1]
              unless values.nil?
                values.map! {|e| e.gsub(/;/, '') }
              end
              unless key.nil? or key[0..0] == "#"
                location_items.push({:key => key, :values => values})
              end
              ptr += 1
            end
            items.push({:key => location_name, :values => location_items})
          else
            key = line[0]
            values = line[1..-1]
            unless values.nil?
              values.map! {|e| e.gsub(/;/, '') }
            end
            unless key.nil? or key[0..0] == "#"
              items.push({:key => key, :values => values})
            end
          end
          ptr += 1
        end
        server_blocks[server_blocks.count.to_i] = items
      end
      ptr += 1
    end
    return {:upstream_blocks => upstream_blocks, :server_blocks => server_blocks}
  end
end