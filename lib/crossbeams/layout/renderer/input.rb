# frozen_string_literal: true

module Crossbeams
  module Layout
    module Renderer
      # Render an input field.
      class Input < Base # rubocop:disable Metrics/ClassLength
        def configure(field_name, field_config, page_config)
          @field_name   = field_name
          @field_config = field_config
          @page_config  = page_config
          @caption      = field_config[:caption] || present_field_as_label(field_name)
        end

        def render # rubocop:disable Metrics/AbcSize
          datalist = build_datalist
          date_related_value_getter
          setup_pattern_title

          <<-HTML
          <div #{wrapper_id} class="#{div_class}"#{wrapper_visibility}>#{hint_text}#{copy_prefix}
            <input type="#{input_type}" value="#{CGI.escapeHTML(value.to_s)}" #{name_attribute} #{field_id} #{attr_list(datalist).join(' ')}>#{copy_suffix}
            <label for="#{id_base}">#{@caption}#{error_state}#{hint_trigger}</label>
            #{datalist}
          </div>
          HTML
        end

        private

        def copy_prefix
          return '' unless @field_config[:copy_to_clipboard]

          '<div class="cbl-copy-wrapper">'
        end

        def copy_suffix
          return '' unless @field_config[:copy_to_clipboard]

          %(<button type="button" id="#{id_base}_clip" class="cbl-clipcopy" data-clipboard="copy" title="Copy to clipboard">
          #{Icon.render(:copy, attrs: ["id='#{id_base}_clip_i'", 'data-clipboard="copy"'])}
            </button></div>)
        end

        def subtype
          @field_config[:subtype] || @field_config[:renderer]
        end

        def input_type # rubocop:disable Metrics/CyclomaticComplexity
          case subtype
          when :integer, :numeric, :number
            'number'
          when :email
            'email'
          when :url
            'url'
          when :password
            'password'
          when :date, :month, :time
            date_related_input_type(subtype)
          when :file
            'file'
          else
            'text'
          end
        end

        def date_related_input_type(in_type)
          case in_type
          when :date     # yyyy-mm-dd
            'date'
          when :month    # yyyy-mm
            'month'
          when :time     # HH:MM
            'time'
          end
        end

        DATE_VALUE_GETTERS = {
          date: lambda { |d|
            return '' if d.nil?

            d.is_a?(String) ? d : d.strftime('%Y-%m-%d')
          },
          time: lambda { |t|
            return '' if t.nil?

            t.is_a?(String) ? t : t.strftime('%H:%M')
          },
          month: lambda { |d|
            return '' if d.nil?

            d.is_a?(String) ? d : d.strftime('%Y-%m')
          }
        }.freeze

        def date_related_value_getter
          @value_getter = DATE_VALUE_GETTERS[subtype]
        end

        def value
          res = form_object_value
          res = override_with_form_value(res)
          if res.is_a?(BigDecimal) # TODO: read other frameworks to see best way of handling this...
            res.to_s('F')
          else
            @value_getter.nil? ? res : @value_getter.call(res)
          end
        end

        def build_datalist
          return nil unless @field_config[:datalist] && !@field_config[:datalist].empty?

          s = +''
          @field_config[:datalist].each do |opt|
            s << "<option value=\"#{opt}\">\n"
          end
          <<-HTML
          <datalist id="#{id_base}_listing">
            #{s}
          </datalist>
          HTML
        end

        PATTERN_REGEX = {
          no_spaces: '[^\s]+',
          valid_filename: '[^\s\/\\\*?:&amp;&quot;<>\|]+',
          lowercase_underscore: '[a-z_]*',
          alphanumeric: '[a-zA-Z0-9]*',
          ipv4_address: '(?:(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])(\.(?!$)|$)){4}'
        }.freeze

        PATTERN_TITLES = {
          no_spaces: 'no spaces allowed',
          valid_filename: 'no spaces, asterisks, question marks, greater-than or less-than signs, colons, pipes, quotes, ampersands or slashes allowed',
          lowercase_underscore: 'only alphabetic characters and underscore (_) allowed',
          alphanumeric: 'only alphanumeric characters allowed (a-z and 0-9)',
          ipv4_address: 'must be a valid IP v4 address'
        }.freeze

        def build_pattern(pattern)
          val = case pattern
                when String
                  pattern.sub('/^', '').sub('$/', '')
                when Regexp
                  pattern.inspect.sub('/^', '').sub('$/', '')
                else
                  PATTERN_REGEX[pattern]
                end
          return nil if val.nil?

          "pattern=\"#{val}\""
        end

        def setup_pattern_title
          return if @field_config[:pattern_msg]

          title = PATTERN_TITLES[@field_config[:pattern]]
          @field_config[:pattern_msg] = title unless title.nil?
        end

        def attr_list(datalist) # rubocop:disable Metrics/AbcSize
          [
            attr_class,
            attr_placeholder,
            attr_pattern_title,
            attr_title,
            attr_pattern,
            attr_minvalue,
            attr_maxvalue,
            attr_minlength,
            attr_maxlength,
            attr_readonly,
            attr_disabled,
            attr_required,
            attr_step,
            attr_upper,
            attr_lower,
            attr_accept,
            attr_autofocus,
            behaviours,
            attr_datalist(datalist)
          ].compact
        end

        def attr_class
          res = ['cbl-input']
          res << 'cbl-to-upper' if @field_config[:force_uppercase]
          res << 'cbl-to-lower' if @field_config[:force_lowercase]
          %(class="#{res.join(' ')}")
        end

        def attr_placeholder
          return "placeholder=\"#{@field_config[:placeholder]}\"" if @field_config[:placeholder]
        end

        def attr_pattern_title
          return "title=\"#{@field_config[:pattern_msg]}\"" if @field_config[:pattern_msg] && !@field_config[:title]
        end

        def attr_title
          return "title=\"#{@field_config[:title]}\"" if @field_config[:title]
        end

        def attr_pattern
          return build_pattern(@field_config[:pattern]) if @field_config[:pattern]
        end

        def attr_minvalue
          return '' unless @field_config[:minvalue]
          raise ArgumentError, "Input: minvalue is not applicable for type #{input_type}" unless %w[date month week time number range].include?(input_type)

          "min=\"#{@field_config[:minvalue]}\""
        end

        def attr_maxvalue
          return '' unless @field_config[:maxvalue]
          raise ArgumentError, "Input: maxvalue is not applicable for type #{input_type}" unless %w[date month week time number range].include?(input_type)

          "max=\"#{@field_config[:maxvalue]}\""
        end

        def attr_minlength
          return '' unless @field_config[:minlength]
          raise ArgumentError, "Input: minlength is not applicable for type #{input_type}" unless %w[text search url tel email password].include?(input_type)

          "minlength=\"#{@field_config[:minlength]}\""
        end

        def attr_maxlength
          return '' unless @field_config[:maxlength]
          raise ArgumentError, "Input: maxlength is not applicable for type #{input_type}" unless %w[text search url tel email password].include?(input_type)

          "maxlength=\"#{@field_config[:maxlength]}\""
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

        def attr_step
          return 'step="any"' if subtype == :numeric
        end

        def attr_upper
          return %{onblur="this.value = this.value.toUpperCase()"} if @field_config[:force_uppercase]
        end

        def attr_lower
          return %{onblur="this.value = this.value.toLowerCase()"} if @field_config[:force_lowercase]
        end

        def attr_accept
          return %(accept="#{@field_config[:accept]}") if @field_config[:accept]
        end

        def attr_autofocus
          return 'autofocus' if @field_config[:autofocus]
        end

        def attr_datalist(datalist)
          %(list="#{@page_config.name}_#{@field_name}_listing") unless datalist.nil?
        end
      end
    end
  end
end
