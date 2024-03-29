# frozen_string_literal: true

module Crossbeams
  module Layout
    # PageNode - base class for other nodes to inherit from.
    module PageNode
      def add_csrf_tag(tag)
        @nodes.each { |node| node.add_csrf_tag(tag) if node.respond_to?(:add_csrf_tag) }
      end
    end
  end
end
