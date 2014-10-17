module OdReport
  module Fields
    using FixNumbers
    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }

    def field_replace!(_node, data_item = nil)
      txt = _node.inner_html

      @fields.each do |f|
        val = f.get_value(data_item)
        txt.gsub!(f.to_placeholder, sanitize(val))
      end

      _node.inner_html = txt
    end

    private

    def sanitize(txt)
      txt = html_escape(txt)
      txt = ods_linebreak(txt)
      txt
    end

    def html_escape(s)
      return "" unless s
      s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
    end

    def ods_linebreak(s)
      return "" unless s
      s.to_s.gsub("\n", "</text:p><text:p>")
    end
  end
end
