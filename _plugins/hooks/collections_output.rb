# Allows 'output: false' to be set individually, instead of only for the entire collection.
module Jekyll
  module CollectionsOutput
    module_function

    def run(site)
      site.collections.each_value do |collection|
        collection.docs.each do |document|
          return unless document.data['output'] == false

          def document.write?
            false
          end

          def document.output
            false
          end

          def document.render_with_liquid?
            false
          end

          def document.place_in_layout?
            false
          end
        end
      end
    end
  end
end
