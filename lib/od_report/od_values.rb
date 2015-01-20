module OdValues
  POINT_CHAR = ','

  refine Date do
    def od_value
      strftime("%Y-%m-%dT%H:%M:%S")
    end

    def od_type
      'date'
    end

    def value_attribute_name
      'date-value'
    end

    def od_s
      strftime("%Y.%m.%d")
    end
  end

  refine Numeric do
    def od_value
      (divmod(1)[1].zero? ? round : self).to_s
    end

    def od_type
      'float'
    end

    def value_attribute_name
      'value'
    end

    def od_s
      break_apart.compact.join(POINT_CHAR)
    end

    def break_apart
      left, right = round(2).to_s.split('.')
      [left, right == '0' ? nil : right.ljust(2, '0')]
    end
  end

  refine Object do
    def od_value
      escape_value
    end

    def od_s(escape_html = true)
      if escape_html
        escape_value
      else
        to_s
      end
    end

    def od_type
      'string'
    end

    def value_attribute_name
      'string'
    end

    def escape_value
      CGI.escapeHTML(to_s)
    end
  end
end
