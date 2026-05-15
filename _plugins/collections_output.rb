# Allows 'output: false' to be set indvidually, instead of only for the entire collection.
Jekyll::Hooks.register :documents, :pre_render do |document|
  if document.data['output'] == false
    def document.write?
      false
    end

    def document.output
      false
    end
  end
end
