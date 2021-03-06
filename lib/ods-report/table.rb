module OdReport::ODS
  class Table
    using OdValues
    attr_accessor :options, :tables, :table_name

    def initialize(opts)
      if opts[:collection].is_a?(Hash)
        @records = create_records_from_hash(opts[:collection])
      else
        @records = opts[:collection]
      end
      @table_name = opts[:name]
      instance_variable_set("@#{@table_name}", @records)
      if defined?(opts[:name])
        self.class.send(:attr_reader, @table_name)
      else
        raise "Invalid collection name: #{@table_name}"
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
          if row.text.match(OdReport::ODS::RegExps::BLOCK) # <% %>
            operand = row.text.match(OdReport::ODS::RegExps::BLOCK)[1]
            if opened_operand?(operand)
              current_block << [index, row]
              count_opened_operands += 1
            else # closed operand
              if count_opened_operands > 0
                current_block << [index, row]
                count_opened_operands -= 1
                if count_opened_operands == 0
                  blocks << current_block
                  current_block = []
                end
              end
            end
          elsif count_opened_operands > 0
            current_block << [index, row]
          end
        end

        if blocks.present?
          result_from_blocks = []
          blocks.each do |block|
            result, skip = evaluate_block(block)
            next if skip
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

    def check_table(code)
      if res = code.match(/\s*(\w+)\./)
        res[1] != table_name.to_s
      else
        false
      end
    end

    def evaluate_block(block)
      skip_block = false
      fragment_doc = ''
      block_code = ''
      table_opened = false
      block.each do |_, row|
        row_text = row.to_xml.tr("\n", ' ')
        if row_text.match(OdReport::ODS::RegExps::VALUE) # <%= %>
          block_code << "fragment_doc << '#{gsub_cells(row.dup)}'\n"
        elsif row_text.match(OdReport::ODS::RegExps::BLOCK) # <% %>
          code = row_text.match(OdReport::ODS::RegExps::BLOCK)[1]
          skip_block = check_table(code) if opened_operand?(code) && !table_opened
          table_opened = true
          block_code << code + "\n"
        else # str
          block_code << "fragment_doc << '#{row_text}'\n"
        end
      end
      block_code << "fragment_doc\n"
      res = eval(escape_code(block_code)) unless skip_block
      [res, skip_block]
    end

    def gsub_cells(row)
      row.xpath('table:table-cell').each do |cell|
        next unless cell.to_xml =~ OdReport::ODS::RegExps::VALUE
        value_name = cell.to_xml.match(OdReport::ODS::RegExps::VALUE)[1]
        cell["office:'+(#{value_name}).value_attribute_name+'"] = "'+(#{value_name}).od_value+'"
        cell["office:value-type"] = "'+(#{value_name}).od_type+'"
        cell.xpath("text:p").each { |t| t.content = "'+(#{value_name}).od_s+'" }
      end
      row.to_xml.gsub("\n", " ")
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
