# frozen_string_literal: true

module Crossbeams
  module Layout
    # A link renderer - for rendering a link outside a form.
    class Link
      include PageNode
      attr_reader :text, :url, :style, :behaviour, :css_class

      def initialize(options) # rubocop:disable Metrics/CyclomaticComplexity
        @text      = options[:text]
        @url       = options[:url]
        raise ArgumentError, 'Crossbeams::Layout::Link requires text and url options' if @text.nil? || @url.nil?
        @style     = options[:style] || :link
        @behaviour = options[:behaviour] || :direct # popup window, popup dialog, modal...
        @css_class = options[:css_class] || ''
        @grid_id   = options[:grid_id] || ''
        @nodes     = []
      end

      # Is this node invisible?
      #
      # @return [boolean] - true if it should not be rendered at all, else false.
      def invisible?
        false
      end

      # Is this node hidden?
      #
      # @return [boolean] - true if it should be rendered as hidden, else false.
      def hidden?
        false
      end

      # Render this node as HTML link.
      #
      # @return [string] - HTML representation of this node.
      def render
        <<-HTML
        <a href="#{url}"#{class_strings}#{behaviour_string}#{grid_string}>#{render_text}</a>
        HTML
      end

      private

      def class_strings
        if style == :button
          %( class="f6 link dim br2 ph3 pv2 dib white bg-silver #{css_class}")
        elsif style == :back_button
          %( class="f6 link dim br2 ph3 pv2 dib white bg-dark-blue #{css_class}")
        else
          css_class.empty? ? '' : css_class
        end
      end

      def render_text
        if style == :back_button
          %(<svg class="cbl-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><polygon points="3.828 9 9.899 2.929 8.485 1.515 0 10 .707 10.707 8.485 18.485 9.899 17.071 3.828 11 20 11 20 9 3.828 9"/></svg> #{text})
        else
          text
        end
      end

      def behaviour_string
        if @behaviour == :popup
          ' data-popup-dialog="true"'
        elsif @behaviour == :replace_dialog
          ' data-replace-dialog="true"'
        else
          ''
        end
      end

      def grid_string
        @grid_id == '' ? '' : %( data-grid-id="#{@grid_id}")
      end
    end
  end
end
