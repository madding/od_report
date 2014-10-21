module OdReport::ODS
  module RegExps
    BLOCK = /\[%[^=%](.+)%\]/
    VALUE = /\[%=([^%]+)%\]/
  end
end
