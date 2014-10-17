module OdReport::ODS
  class Table
    using FixNumbers
    attr_accessor :options, :tables

    def initialize(opts)
      if opts[:collection].is_a?(Hash)
        @records = create_records_from_hash(opts[:collection])
      else
        @records = opts[:collection]
      end

      instance_variable_set("@#{opts[:name]}", @records)
      if defined?(opts[:name])
        self.class.send(:attr_reader, opts[:name])
      else
        raise "Invalid collection name: #{opts[:name]}"
      end

      @tables  = []
      @options = {}
    end

    def add_column(name, data_field=nil, &block)
      opts = {:name => name, :data_field => data_field}
      field = Field.new(opts, &block)
      @fields << field
    end

    def add_option(name, data)
      @options[name] = data
    end

    def add_table(table_name, collection_field, opts={})
      opts.merge!(:name => table_name)
      tab = Table.new(opts)
      @tables << tab

      yield(tab) if block_given?
    end

    def replace!(doc, row = nil)
      doc.xpath('//table:table').each do |table|
        blocks = []
        count_opened_operands = 0
        current_block = []
        table.xpath('//table:table-row').each_with_index do |row, index|
          if row.text.match(/\[%[^=](.+)%\]/) # <% %>
            operand = row.text.match(/\[%(.+)%\]/)[1]
            if opened_operand?(operand)
              current_block << [index, row.to_s]
              count_opened_operands += 1
            else # closed operand
              if count_opened_operands > 0
                current_block << [index, row.to_s]
                count_opened_operands -= 1
                if count_opened_operands == 0
                  blocks << current_block
                  current_block = []
                end
              end
            end
          elsif count_opened_operands > 0
            current_block << [index, row.to_s]
          end
        end

        if blocks.present?
          result_from_blocks = []
          blocks.each do |block|
            result = evaluate_block(block)
            begin_row = block.first.first
            end_row = block.last.first
            result_from_blocks << [begin_row, end_row, result]
          end

          result_from_blocks.reverse.each do |block|
            replace_block!(table, *block)
          end
        end
      end
    end

    private
    def evaluate_block(block)
      fragment_doc = ''
      block_code = ''
      block.each do |index, row|
        row = row.gsub("\n", " ")
        if row.match(/\[%=([^%]+)%\]/) # <%= %>
          replaced_row = row.gsub(/\[%=([^%]+)%\]/m, '\' + (\1).to_s + \'')
          block_code += "fragment_doc << '" + replaced_row + "'\n"
        elsif row.match(/\[%([^%]+)%\]/) # <% %>
          block_code += row.match(/\[%([^%]+)%\]/)[1] + "\n"
        else # str
          block_code += "fragment_doc << '#{row}' \n"
        end
      end
      block_code += "fragment_doc \n"
      eval(escape_code(block_code))
    end

    def escape_code(code)
      [[/&apos;/, "'"], [/&gt;/, '>'], [/&lt/, '<'],
       [/&quot;/, '"'], [/&amp;/, '&']].each do |pattern, replace|
        code.gsub!(pattern, replace)
      end
      code
    end

    def replace_block!(table, begin_row, end_row, block)
      table.xpath('//table:table-row')[begin_row+1..end_row].map(&:remove)
      table.xpath('//table:table-row')[begin_row].replace(block)
    end

    def opened_operand?(operand)
      if operand.match(/(.+\sdo\s\|.+\|)|(\s*if\s.+)|(\s*begin\s*)/)
        true
      else
        false
      end
    end

    def create_records_from_hash(hash)
      OdReport.create_records_from_array(hash[:column_names], hash[:data])
    end
  end
end
