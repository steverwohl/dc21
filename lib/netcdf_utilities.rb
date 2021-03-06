class NetcdfUtilities

  def initialize(data_file_path)
    output = %x(ncdump -x -h #{data_file_path})
    @header_info = Nokogiri::XML.parse(output)
    @header_info.remove_namespaces!

    output = %x(ncks --xml -v time #{data_file_path})
    @var_info = Nokogiri::XML.parse(output)
    @var_info.remove_namespaces!
  end

  def extract_external_id
    id = @header_info.xpath('/netcdf/attribute[@name="id"]')
    return id.xpath('./@value').text
  end

  def formatted_id(id, start_time, end_time)
    formatted_id = id
    if not start_time.blank?
      formatted_id = id + '__' + start_time.strftime('%Y-%m-%d %H:%M')
    end
    if not end_time.blank?
      formatted_id = formatted_id + '_' + end_time.strftime('%Y-%m-%d %H:%M')
    end
    return formatted_id
  end

  def extract_start_end_time
    start_time = nil
    end_time = nil
    time_len = @var_info.xpath('//dimension/@length').text.to_i
    var = @var_info.xpath('.//variable[@name="time"]')
    value = var.xpath('.//values').text
    if time_len >= 1
      type = extract_attribute_from_element(var, 'type')
      unit = extract_attribute_from_variable(var, 'units')
      start_time, end_time = determine_start_end_time(type, unit, value)
    end
    return start_time, end_time
  end

  def determine_start_end_time(type,unit,values)
    time_series = []
    start_time = nil
    end_time = nil
    time_series = values.split

    start_val = time_series[0].to_f
    end_val = time_series[-1].to_f
    if unit.include? 'since'
      split_str = unit.split(' since ')
      time_unit = split_str[0]
      time_method = time_unit.singularize
      time_since = Time.parse(split_str[-1])
      begin
        start_time = time_since + start_val.send(time_method)
        end_time = time_since + end_val.send(time_method)
      rescue
        start_time = time_since + start_val.to_i.send(time_method)
        end_time = time_since + end_val.to_i.send(time_method)
      end
    end
    return start_time, end_time
  end

  def extract_all_variables
    return @header_info.xpath('//variable')
  end

  def extract_attribute_from_element(var, attr)
    return var.xpath("./@#{attr}").text
  end

  def extract_attribute_from_variable(var, attr)
    return var.xpath("./attribute[@name='#{attr}']/@value").text
  end

  def extract_all_dimensions
    return @header_info.xpath('//dimension')
  end

  def extract_all_top_lvl_attributes
    return @header_info.xpath('/netcdf/attribute')
  end

end
