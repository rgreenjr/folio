class AsyncCommand
  def initialize(&block)
    # Each thread gets its own FIFO queue upon which we will dispatch
    # the delayed computation passed in the &block variable.
    Thread.current[:futures] ||= Dispatch::Queue.new("me.folioapp.async-#{Thread.current.object_id}")
    @group = Dispatch::Group.new 
    # Asynchronously dispatch the future to the thread-local queue.
    Thread.current[:futures].async(@group) { @value = block.call }
  end
  def value
    # Wait for the computation to finish (if not already done)
    @group.wait
    # then just return the value in question.
    @value
  end
end
