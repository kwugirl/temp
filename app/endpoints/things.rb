module API
  module Endpoints
    class Things < Base
      namespace "/things" do
        get do
          range_header = RangeHeader.parse(request.env["HTTP_RANGE"].to_s)

          query = Thing.order(range_header.field => range_header.order).limit(range_header.page_size).all
          if range_header.start_identifier
            if range_header.inclusive
              query = query.where("#{range_header.field} >= #{range_header.start_identifier}")
            else
              query = query.where("#{range_header.field} > #{range_header.start_identifier}")
            end
          end
          if range_header.end_identifier
            query = query.where("#{range_header.field} < #{range_header.end_identifier}")
          end
          things = query

          next_range = "#{range_header.field} ]#{things.last[range_header.field]}..; max=#{range_header.page_size}"
          next_range += ", order=#{range_header.order}" unless range_header.order == RangeHeader::DEFAULT_ORDER
          headers 'Content-Range' => "#{range_header.field} #{things.first[range_header.field]}..#{things.last[range_header.field]}",
            'Next-Range' => next_range

          things.to_json
        end
      end

      class RangeHeader
        def self.parse(header)
          field = nil
          start_identifier = nil
          end_identifier = nil
          inclusive = true
          page_size = nil
          order = nil

          header_parts = /^(\S+) (\[|\])?(\d*)..(\d*)(; )?(max=(\d+))?(, )?(order=(asc|desc))?$/.match(header) || ""

          field = header_parts[1] unless header_parts[1].to_s.empty?
          inclusive = false if !header_parts[2].to_s.empty? && header_parts[2] == "]"
          start_identifier = header_parts[3] unless header_parts[3].to_s.empty?
          end_identifier = header_parts[4] unless header_parts[4].to_s.empty?
          page_size = header_parts[7].to_i unless header_parts[7].to_s.empty?
          order = header_parts[10] unless header_parts[10].to_s.empty?

          RangeHeader.new(field, start_identifier, end_identifier, inclusive, page_size, order)
        end

        attr_reader :field, :start_identifier, :end_identifier, :inclusive, :page_size, :order
        DEFAULT_ORDER = "asc"

        def initialize(field, start_identifier=nil, end_identifier=nil, inclusive=true, page_size=200, order=DEFAULT_ORDER)
          @field = field || "id"
          @start_identifier = start_identifier
          @end_identifier = end_identifier
          @inclusive = inclusive
          @page_size = page_size || 200
          @order = order || DEFAULT_ORDER
        end
      end
    end
  end
end
