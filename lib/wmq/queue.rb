module WMQ
  class Queue
    # Open a queue, then close the queue once the supplied code block completes
    #
    # Parameters:
    # * Since the number of parameters can vary dramatically, all parameters are passed by name in a hash
    # * Summary of parameters and their WebSphere MQ equivalents:
    #  queue = Queue.new(                                      # WebSphere MQ Equivalents:
    #    queue_manager:         queue_manager,                 # n/a : Instance of QueueManager
    #    q_name:                'Queue Name',                  # MQOD.ObjectName
    #    q_name:                { queue_manager:'QMGR_name',   # MQOD.ObjectQMgrName
    #                             q_name:       'q_name'}
    #    mode:                  :input or :input_shared or :input_exclusive or :output,
    #    fail_if_quiescing:     true                           # MQOO_FAIL_IF_QUIESCING
    #    fail_if_exists:        true, # For dynamic queues, fail if it already exists
    #    open_options:          WMQ::MQOO_BIND_ON_OPEN | ...   # MQOO_*
    #    close_options:         WMQ::MQCO_DELETE_PURGE         # MQCO_*
    #    dynamic_q_name:        'Name of Dynamic Queue'        # MQOD.DynamicQName
    #    alternate_user_id:     'userid',                      # MQOD.AlternateUserId
    #    alternate_security_id: ''                             # MQOD.AlternateSecurityId
    #  )
    #
    # Mandatory Parameters
    # * :queue_manager
    #   * An instance of the WMQ::QueueManager class. E.g. QueueManager.new
    #   * Note: This is _not_ the queue manager name!
    #
    # * :q_name => String
    #   * Name of the existing WebSphere MQ local queue, model queue or remote queue to open
    #   * To open remote queues for which a local remote queue definition is not available
    #     pass a Hash as q_name (see q_name => Hash)
    #       OR
    # * :q_name => Hash
    #   * q_name => String
    #     * Name of the existing WebSphere MQ local queue, model queue or remote queue to open
    #   * :q_mgr_name => String
    #     * Name of the remote WebSphere MQ queue manager to send the message to.
    #     * This allows a message to be written to a queue on a remote queue manager
    #       where a remote queue definition is not defined locally
    #     * Commonly used to reply to messages from remote systems
    #     * If q_mgr_name is the same as the local queue manager name then the message
    #       is merely written to the local queue.
    #     * Note: q_mgr_name should only be supplied when putting messages to the queue.
    #         It is not possible to get messages from a queue on a queue manager other
    #         than the currently connected queue manager
    #
    # * :mode => Symbol
    #   * Specify how the queue is to be opened
    #     * :output
    #       * Open the queue for output. I.e. WMQ::Queue#put will be called
    #          Equivalent to: MQOO_OUTPUT
    #     * :input
    #       * Open the queue for input. I.e. WMQ::Queue#get will be called.
    #       * Queue sharing for reading from the queue is defined by the queue itself.
    #         By default most queues are set to shared. I.e. Multiple applications
    #         can read and/or write from the queue at the same time
    #          Equivalent to: MQOO_INPUT_AS_Q_DEF
    #     * :input_shared
    #       * Open the queue for input. I.e. WMQ::Queue#get will be called.
    #       * Explicitly open the queue so that other applications can read or write
    #         from the same queue
    #          Equivalent to: MQOO_INPUT_SHARED
    #     * :input_exclusive
    #       * Open the queue for input. I.e. WMQ::Queue#get will be called.
    #       * Explicitly open the queue so that other applications cannot read
    #         from the same queue. Does _not_ affect applications writing to the queue.
    #       * Note: If :input_exclusive is used and connectivity the queue manager is lost.
    #         Upon restart the queue can still be "locked". The application should retry
    #         every minute or so until the queue becomes available. Otherwise, of course,
    #         another application has the queue open exclusively.
    #          Equivalent to: MQOO_INPUT_EXCLUSIVE
    #     * :browse
    #       * Browse the messages on the queue _without_ removing them from the queue
    #       * Open the queue for input. I.e. WMQ::Queue#get will be called.
    #       * Note: It is necessary to specify WMQ::MQGMO_BROWSE_FIRST before the
    #         first get, then set WMQ::MQGMO_BROWSE_NEXT for subsequent calls.
    #       * Note: For now it is also necessary to specify these options when calling
    #         WMQ::Queue#each. A change will be made to each to address this.
    #          Equivalent to: MQOO_BROWSE
    #     * Default: None.
    #       If no :mode is supplied, then :open_options must be supplied.
    #       In this way any custom combination of open options can be supplied.
    #
    # Optional Parameters
    # * :fail_if_quiescing => true or false
    #   * Determines whether the WMQ::Queue#open call will fail if the queue manager is
    #     in the process of being quiesced.
    #   * Note: If set to false, the MQOO_FAIL_IF_QUIESCING flag will not be removed if
    #     it was also supplied in :open_options. However, if set to true it will override
    #     this value in :open_options
    #   * Note: This interface differs from other WebSphere MQ interfaces,
    #     they do not default to true.
    #      Default: true
    #      Equivalent to: MQOO_FAIL_IF_QUIESCING
    #
    # * :open_options => FixNum
    #   * One or more of the following values:
    #       WMQ::MQOO_INQUIRE
    #       WMQ::MQOO_SET
    #       WMQ::MQOO_BIND_ON_OPEN
    #       WMQ::MQOO_BIND_NOT_FIXED
    #       WMQ::MQOO_BIND_AS_Q_DEF
    #       WMQ::MQOO_SAVE_ALL_CONTEXT
    #       WMQ::MQOO_PASS_IDENTITY_CONTEXT
    #       WMQ::MQOO_PASS_ALL_CONTEXT
    #       WMQ::MQOO_SET_IDENTITY_CONTEXT
    #       WMQ::MQOO_SET_ALL_CONTEXT
    #   * Multiple values can be or'd together. E.g.
    #       :open_options=>WMQ::MQOO_BIND_ON_OPEN | WMQ::MQOO_SAVE_ALL_CONTEXT
    #   * Please see the WebSphere MQ documentation for more details on the above options
    #
    # * :close_options => FixNum
    #   * One of the following values:
    #       WMQ::MQCO_DELETE
    #       WMQ::MQCO_DELETE_PURGE
    #   * Please see the WebSphere MQ documentation for more details on the above options
    #
    # * :dynamic_q_name => String
    #   * If a model queue name is supplied to :q_name then the final queue name that is
    #     created is specified using :dynamic_q_name
    #   * A complete queue name can be specified. E.g. 'MY.LOCAL.QUEUE'
    #   * Or, a partial queue name can be supplied. E.g. 'MY.REPLY.QUEUE.*'
    #     In this case WebSphere MQ will automatically add numbers to the end
    #     of 'MY.REPLY.QUEUE.' to ensure this queue name is unique.
    #   * The most common use of :dynamic_q_name is to create a temporary dynamic queue
    #     to which replies can be posted for this instance of the program
    #   * When opening a model queue, :dynamic_q_name is optional. However it's use is
    #     recommended in order to make it easier to identify which application a
    #     dynamic queue belongs to.
    #
    # * :fail_if_exists => true or false
    #   * Only applicable when opening a model queue
    #   * When opening a queue dynamically, sometimes the :dynamic_q_name already
    #     exists. Under this condition, if :fail_if_exists is false, the queue is
    #     automatically re-opened using the :dynamic_q_name. The :q_name field is ignored.
    #   * This feature is usefull when creating _permanent_ dynamic queues.
    #     (The model queue has the definition type set to Permanent: DEFTYPE(PERMDYN) ).
    #     * In this way it is not necessary to create the queues before running the program.
    #      Default: true
    #
    # * :alternate_user_id [String]
    #   * Sets the alternate userid to use when messages are put to the queue
    #   * Note: It is not necessary to supply WMQ::MQOO_ALTERNATE_USER_AUTHORITY
    #     since it is automatically added to the :open_options when :alternate_user_id
    #     is supplied
    #   * See WebSphere MQ Application Programming Reference: MQOD.AlternateUserId
    #
    # * :alternate_security_id [String]
    #   * Sets the alternate security id to use when messages are put to the queue
    #   * See WebSphere MQ Application Programming Reference: MQOD.AlternateSecurityId
    #
    # Note:
    # * It is more convenient to use WMQ::QueueManager#open_queue, since it automatically supplies
    #   the parameter :queue_manager
    # * That way :queue_manager parameter is _not_ required
    #
    # Example:
    #   # Put 10 Hello World messages onto a queue
    #   require 'wmq/wmq_client'
    #
    #   WMQ::QueueManager.connect(q_mgr_name: 'REID', connection_name: 'localhost(1414)') do |qmgr|
    #     WMQ::Queue.open(
    #       queue_manager: qmgr,
    #       q_name:        'TEST.QUEUE',
    #       mode:          :output
    #     ) do |queue|
    #       10.times { |counter| queue.put(data: "Hello World #{counter}") }
    #     end
    #   end
    def self.open(**opts)
      queue = new(**opts)
      return false if !queue.open

      if block_given?
        begin
          yield queue
        ensure
          queue.close
        end
      end

      queue
    end

    def self.create_finalizer(queue_struct)
      # Create finalizer proc that captures queue_struct
      proc {
        Queue.finalize(queue_struct)
      }
    end
  end
end
