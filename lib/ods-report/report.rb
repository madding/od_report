module OdReport::ODS
  class Report
    include Fields

    attr_accessor :fields, :tables, :file, :texts

    def initialize(template_name, &block)

      @file = OdReport::File.new(template_name)

      @texts = []
      @fields = []
      @tables = []

      yield(self)
    end

    def add_field(field_tag, value='', &block)
      opts = {:name => field_tag, :value => value}
      field = OdReport::Field.new(opts, &block)
      @fields << field
    end

    def add_text(field_tag, value='', &block)
      opts = {:name => field_tag, :value => value}
      text = Text.new(opts)
      @texts << text
    end

    def add_table(table_name, collection, opts={})
      opts.merge!(:name => table_name, :collection => collection)
      tab = Table.new(opts)
      @tables << tab

      yield(tab) if block_given?
    end

    def generate(dest = nil, &block)
      @file.create(dest)

      @file.update('content.xml') do |txt|
        parse_document(txt) do |doc|
          replace_fields!(doc)
          replace_tables!(doc)
        end
      end

      if block_given?
        yield @file.path
        @file.remove
      end

      @file.path
    end

    def cleanup
      @file.remove
    end

    private

    def parse_document(txt)
      doc = Nokogiri::XML(txt)
      yield doc
      txt.replace(doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML))
      txt.gsub!(/<([\/]*)(table:p)>/, '<\1text:p>') # fix bug in create document fragment in nokogiri
      txt
    end

    def replace_fields!(content)
      field_replace!(content)
    end

    def replace_tables!(content)
      @tables.each do |table|
        table.replace!(content)
      end
    end
  end
end
