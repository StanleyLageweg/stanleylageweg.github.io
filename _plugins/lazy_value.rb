class LazyValue
  def initialize(&block)
    @block = block
    @value = nil
    @computed = false
  end

  def method_missing(method, *args, &block)
    unless @computed
      @value = @block.call
      @computed = true
    end
    @value.public_send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    unless @computed
      @value = @block.call
      @computed = true
    end
    value.respond_to?(method, include_private)
  end
end  
