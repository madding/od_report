module OdReport::ODF
  module Fields
    using OdValues

    def field_replace!(node, data_item = nil)
      txt = node.inner_html

      @fields.each do |f|
        val = f.get_value(data_item).od_s
        txt.gsub!(f.to_placeholder, ods_linebreak(val))
      end

      node.inner_html = txt
    end

    def ods_linebreak(s)
      return '' unless s
      s.to_s.gsub("\n", '</text:p><text:p>')
    end
  end
end
