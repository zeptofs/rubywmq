module WMQ
  class Queue
    def self.create_finalizer(queue_struct)
      # Create finalizer proc that captures queue_struct
      proc {
        Queue.finalize(queue_struct)
      }
    end
  end
end
