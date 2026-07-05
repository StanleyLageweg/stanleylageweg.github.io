# Allows 'output: false' to be set individually, instead of only for the entire collection.
module Jekyll
  module CollectionsOutput
    module_function

    def run(document)
      return unless document.data['output'] == false

      def document.write?
        false
      end

      def document.output
        false
      end
    end
  end
end
