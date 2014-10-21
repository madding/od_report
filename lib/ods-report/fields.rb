module OdReport::ODS
  module Fields
    def field_replace!(node)
      @fields.each do |f|
        node.search("[text()*='#{f.to_placeholder}']").each do |cell|
          begin
            fail 'Wrong XML inside docunent' unless cell.respond_to? :parent
            cell = cell.parent
          end until cell.name == 'table-cell'
          f.write_to_ods_cell(cell)
        end
      end
    end
  end
end
