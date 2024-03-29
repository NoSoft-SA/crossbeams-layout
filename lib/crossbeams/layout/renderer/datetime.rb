# frozen_string_literal: true

module Crossbeams
  module Layout
    module Renderer
      # Render a date time as separate date and time controls.
      class Datetime < Base
        def configure(field_name, field_config, page_config)
          @field_name = field_name
          @field_config = field_config
          @page_config = page_config
          @caption = field_config[:caption] || present_field_as_label(field_name)
          validate_defaults
        end

        def render # rubocop:disable Metrics/AbcSize
          date_portion = value&.strftime('%Y-%m-%d')
          time_portion = value&.strftime('%H:%M') || default_time_string

          <<-HTML
          <div #{wrapper_id} class="#{div_class}"#{wrapper_visibility}>#{hint_text}
            <input type="date" value="#{CGI.escapeHTML(date_portion.to_s)}" #{name_attribute(:date)}_date #{field_id(:date)}_date data-datetime="date" #{attr_list(:date).join(' ')}>
            <input type="time" value="#{CGI.escapeHTML(time_portion.to_s)}" #{name_attribute(:time)}_time #{field_id(:time)}_time data-datetime="time" #{attr_list(:time).join(' ')}>
            <input type="hidden" value="#{CGI.escapeHTML(value&.strftime('%Y-%m-%dT%H:%M').to_s)}" #{name_attribute} #{field_id}>
            <label for="#{id_base}_date">#{@caption}#{error_state}#{hint_trigger}</label>
          </div>
          HTML
        end

        private

        def value
          @value ||= begin
            res = form_object_value
            val = override_with_form_value(res)
            val = nil if val.is_a?(String) && val.empty?
            val.is_a?(String) ? Time.mktime(*val.split(/-|T|:/)) : val
          end
        end

        def default_time_string
          return nil unless @field_config[:default_hour]

          "#{@field_config[:default_hour].to_s.rjust(2, '0')}:#{(@field_config[:default_minute] || '00').to_s.rjust(2, '0')}"
        end

        def attr_list(type)
          [
            attr_class,
            attr_placeholder,
            attr_title,
            attr_minvalue(type),
            attr_maxvalue(type),
            attr_readonly,
            attr_disabled,
            attr_required,
            behaviours
          ].compact
        end

        def attr_class
          res = ['cbl-input']
          %(class="#{res.join(' ')}")
        end

        def attr_placeholder
          return "placeholder=\"#{@field_config[:placeholder]}\"" if @field_config[:placeholder]
        end

        def attr_title
          return "title=\"#{@field_config[:title]}\"" if @field_config[:title]
        end

        def attr_minvalue(type)
          return '' unless @field_config["minvalue_#{type}".to_sym]

          "min=\"#{@field_config["minvalue_#{type}".to_sym]}\""
        end

        def attr_maxvalue(type)
          return '' unless @field_config["maxvalue_#{type}".to_sym]

          "max=\"#{@field_config["maxvalue_#{type}".to_sym]}\""
        end

        def attr_readonly
          return 'readonly="true"' if @field_config[:readonly] && @field_config[:readonly] == true
        end

        def attr_disabled
          return 'disabled="true"' if @field_config[:disabled] && @field_config[:disabled] == true
        end

        def attr_required
          return 'required="true"' if @field_config[:required] && @field_config[:required] == true
        end

        def validate_defaults
          raise ArgumentError, 'Default hour must be a number from 0 to 23.' if @field_config[:default_hour] && !@field_config[:default_hour].to_i.between?(0, 23)
          raise ArgumentError, 'Default minute must be a number from 0 to 59.' if @field_config[:default_minute] && !@field_config[:default_minute].to_i.between?(0, 59)
        end
      end
    end
  end
end
