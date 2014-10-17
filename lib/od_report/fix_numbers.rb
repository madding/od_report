module FixNumbers
  DELIMITED_REGEX = /(\d)(?=(\d\d\d)+(?!\d))/
  DELIMETER = ' '

  module Fixer
    def to_s
      left, right = round(2).to_s.split('.')
      left.gsub!(DELIMITED_REGEX) { "#{$1}#{DELIMETER}" }
      [left, right].compact.join(',')
    end
  end

  [Float, BigDecimal].each do |num_type|
    refine num_type do
      include Fixer
    end
  end
end
