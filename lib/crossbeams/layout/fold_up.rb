# frozen_string_literal: true

module Crossbeams
  module Layout
    # A FoldUp wraps its content in a <display> element which is folded up by default.
    class FoldUp
      include PageNode
      attr_reader :sequence, :nodes, :page_config, :caption_text

      def initialize(page_config, sequence)
        @caption_text = 'Details'
        @open         = false
        @sequence     = sequence
        @nodes        = []
        @page_config  = page_config
      end

      def caption(value)
        @caption_text = value
      end

      def open!
        @open = true
      end

      def invisible?
        @nodes.all?(&:invisible?)
      end

      def hidden?
        @nodes.all?(&:hidden?)
      end

      def form
        form = Form.new(page_config, sequence, nodes.length + 1)
        yield form
        @nodes << form
      end

      def row
        row = Row.new(page_config, sequence, nodes.length + 1)
        yield row
        @nodes << row
      end

      def add_grid(grid_id, url, options = {})
        @nodes << Grid.new(page_config, grid_id, url, options.merge(fit_height: @fit_height))
      end

      def add_text(text, opts = {})
        @nodes << Text.new(page_config, text, opts)
      end

      def add_notice(text, opts = {})
        @nodes << Notice.new(page_config, text, opts)
      end

      # Add a table to the section.
      def add_table(rows, columns, options = {})
        @nodes << Table.new(page_config, rows, columns, options)
      end

      def add_address(addresses, opts = {})
        @nodes << Address.new(page_config, addresses, opts)
      end

      def add_contact_method(contact_methods, options = {})
        @nodes << ContactMethod.new(page_config, contact_methods, options)
      end

      def add_diff(key)
        @nodes << Diff.new(page_config, key)
      end

      def add_field(name, options = {})
        @nodes << Field.new(page_config, name, options)
      end

      def render
        return '' if invisible?

        row_renders = nodes.reject(&:invisible?).map(&:render).join("\n")
        <<~HTML
          <details class="pv2"#{open_state}>
            <summary class="pointer b blue shadow-3 pa1 mr2">#{caption_text}</summary>
            #{row_renders}
          </details>
        HTML
      end

      private

      def open_state
        @open ? ' open' : ''
      end
    end
  end
end
