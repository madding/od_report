module OdReport::ODF
  module Fields
    def field_replace!(_node, data_item = nil)
      txt = _node.inner_html

      @fields.each do |f|
        val = f.get_value(data_item).od_s
        txt.gsub!(f.to_placeholder, ods_linebreak(val))
      end

      _node.inner_html = txt
    end
  end
end
