require File.expand_path('../od_report/version', __FILE__)
require File.expand_path('../od_report/od_values',  __FILE__)
require File.expand_path('../od_report/field',   __FILE__)
require File.expand_path('../od_report/nested',  __FILE__)
require File.expand_path('../parser/default',    __FILE__)
require File.expand_path('../parser/file',       __FILE__)

# ODF
require File.expand_path('../odf-report/fields',  __FILE__)
require File.expand_path('../odf-report/images',  __FILE__)
require File.expand_path('../odf-report/text',    __FILE__)
require File.expand_path('../odf-report/section', __FILE__)
require File.expand_path('../odf-report/table',   __FILE__)
require File.expand_path('../odf-report/report',  __FILE__)

# ODS
require File.expand_path('../ods-report/fields', __FILE__)
require File.expand_path('../ods-report/table',  __FILE__)
require File.expand_path('../ods-report/report', __FILE__)
require File.expand_path('../ods-report/reg_exps', __FILE__)

require "cgi"

module OdReport
  def self.create_records_from_array(column_names, data)
    records = []
    if column_names.is_a?(Array)
      new_record = Struct.new(*column_names.map(&:to_sym))
    else
      raise "Invalid params, 1 param - array with column names"
    end

    data.each do |rec|
      records << new_record.new(*rec)
    end

    records
  end
end
