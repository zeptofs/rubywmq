# QueueManager ruby methods
module WMQ
  class QueueManager
    # Connect to the queue manager, then disconnect once the supplied code block completes
    #
    # Parameters:
    # * Since the number of parameters can vary dramatically, all parameters are passed by name in a hash
    # * Summary of parameters and their WebSphere MQ equivalents:
    #  WMQ::QueueManager.connect(                             # WebSphere MQ Equivalents:
    #   q_mgr_name:          'queue_manager name',
    #   exception_on_error:  true,                          # n/a
    #   connect_options:     WMQ::MQCNO_FASTBATH_BINDING    # MQCNO.Options
    #
    #   trace_level:         0,                             # n/a
    #
    #   # Common client connection parameters
    #   channel_name:        'svrconn channel name',        # MQCD.ChannelName
    #   connection_name:     'localhost(1414)',             # MQCD.ConnectionName
    #   transport_type:      WMQ::MQXPT_TCP,                # MQCD.TransportType
    #
    #   # Advanced client connections parameters
    #   max_msg_length:      65535,                         # MQCD.MaxMsgLength
    #   security_exit:       'Name of security exit',       # MQCD.SecurityExit
    #   send_exit:           'Name of send exit',           # MQCD.SendExit
    #   receive_exit:        'Name of receive exit',        # MQCD.ReceiveExit
    #   security_user_data:  'Security exit User data',     # MQCD.SecurityUserData
    #   send_user_data:      'Send exit user data',         # MQCD.SendUserData
    #   receive_user_data:   'Receive exit user data',      # MQCD.ReceiveUserData
    #   heartbeat_interval:   1,                            # MQCD.HeartbeatInterval
    #   remote_security_id:  'Remote Security id',          # MQCD.RemoteSecurityId
    #   ssl_cipher_spec:     'SSL Cipher Spec',             # MQCD.SSLCipherSpec
    #   keep_alive_interval: -1,                            # MQCD.KeepAliveInterval
    #   mode_name:           'LU6.2 Mode Name',             # MQCD.ModeName
    #   tp_name:             'LU6.2 Transaction pgm name',  # MQCD.TpName
    #   user_identifier:     'LU 6.2 Userid',               # MQCD.UserIdentifier
    #   password:            'LU6.2 Password',              # MQCD.Password
    #   long_remote_user_id: 'Long remote user identifier', # MQCD.LongRemoteUserId (Ptr, Length)
    #   ssl_peer_name:       'SSL Peer name',               # MQCD.SSLPeerName (Ptr, Length)
    #
    #   # SSL Options
    #   key_repository:      '/var/mqm/qmgrs/.../key',        # MQSCO.KeyRepository
    #   crypto_hardware:     'GSK_ACCELERATOR_NCIPHER_NF_ON', # MQSCO.CryptoHardware
    #   )
    #
    # Optional Parameters
    # * q_mgr_name:  String
    #   * Name of the existing WebSphere MQ Queue Manager to connect to
    #
    #   * Default:
    #      - Server connections will connect to the default queue manager
    #      - Client connections will connect to whatever queue
    #        manager is found at the host and port number as specified
    #        by the connection_name
    #
    # * :exception_on_error => true or false
    #      Determines whether WMQ::WMQExceptions are thrown whenever
    #      an error occurs during a WebSphere MQ operation (connect, put, get, etc..)
    #
    #      Default: true
    #
    # * :connect_options => FixNum
    #   * One or more of the following values:
    #       WMQ::MQCNO_STANDARD_BINDING
    #       WMQ::MQCNO_FASTPATH_BINDING
    #       WMQ::MQCNO_SHARED_BINDING
    #       WMQ::MQCNO_ISOLATED_BINDING
    #       WMQ::MQCNO_ACCOUNTING_MQI_ENABLED
    #       WMQ::MQCNO_ACCOUNTING_MQI_DISABLED
    #       WMQ::MQCNO_ACCOUNTING_Q_ENABLED
    #       WMQ::MQCNO_ACCOUNTING_Q_DISABLED
    #       WMQ::MQCNO_NONE
    #
    #   * Multiple values can be or'd together. E.g.
    #       :connect_options=>WMQ::MQCNO_FASTPATH_BINDING | WMQ::MQCNO_ACCOUNTING_MQI_ENABLED
    #
    #   * Please see the WebSphere MQ MQCNO data type documentation for more details
    #      Default: WMQ::MQCNO_NONE
    #
    # * :trace_level => FixNum
    #   * Turns on low-level tracing of the WebSphere MQ API calls to stdout.
    #     * 0: No tracing
    #     * 1: MQ API tracing only (MQCONNX, MQOPEN, MQPUT, etc..)
    #     * 2: Include Ruby WMQ tracing
    #     * 3: Verbose logging (Recommended for when reporting problems in Ruby WMQ)
    #      Default: 0
    #
    # Common Client Connection Parameters (Client connections only)
    # * :connection_name => String (Mandatory for client connections)
    #   * Connection name, made up of the host name (or ip address) and the port number
    #   * E.g.
    #       'mymachine.domain.com(1414)'
    #       '192.168.0.1(1417)'
    #
    # * :channel_name => String
    #   * Name of SVRCONN channel defined on the QueueManager for Client Connections
    #   * Default Value:
    #       'SYSTEM.DEF.SVRCONN'
    #
    # * :transport_type     => WMQ::MQXPT_TCP,                # MQCD.TransportType
    #   * Valid Values:
    #       WMQ::MQXPT_LOCAL
    #       WMQ::MQXPT_LU62
    #       WMQ::MQXPT_TCP
    #       WMQ::MQXPT_NETBIOS
    #       WMQ::MQXPT_SPX
    #       WMQ::MQXPT_DECNET
    #       WMQ::MQXPT_UDP
    #
    #   * Default Value:
    #       WMQ::MQXPT_TCP
    #
    # * :use_system_connection_data => Boolean
    #   * Used when you want to initialise a client connection, but you want
    #   * to obtain the connection_name and channel_name from one of the system
    #   * configuration methods. These being: mqclient.ini file, MQSERVER ENV
    #   * variable or CCDT.
    #
    # For the Advanced Client Connection parameters, please see the WebSphere MQ documentation
    #
    # Note:
    # * If an exception is not caught in the code block, the current unit of work is
    #   automatically backed out, before disconnecting from the queue manager.
    #
    # Local Server Connection Example:
    #   require 'wmq/wmq'
    #
    #   WMQ::QueueManager.connect(:q_mgr_name=>'REID') do |qmgr|
    #     qmgr.put(:q_name=>'TEST.QUEUE', :data => 'Hello World')
    #   end
    #
    # Client Connection Example:
    #   require 'wmq/wmq_client'
    #
    #   WMQ::QueueManager.connect(
    #               channel_name:     'SYSTEM.DEF.SVRCONN',
    #               transport_type:   WMQ::MQXPT_TCP,
    #               connection_name:  'localhost(1414)' ) do |qmgr|
    #     qmgr.open_queue(q_name: 'TEST.QUEUE', mode: :input) do |queue|
    #
    #       message = WMQ::Message.new
    #       if queue.get(message:  message)
    #         puts "Data Received: #{message.data}"
    #       else
    #         puts 'No message available'
    #       end
    #     end
    #   end
    def self.connect(**opts)
      queue_manager = new(**opts)
      return false if !queue_manager.connect

      if block_given?
        begin
          yield queue_manager
        rescue
          puts "WMQ::QueueManager.connect() Backing out due to unhandled exception"
          queue_manager.backout
          raise
        ensure
          # Backout before automatically disconnecting, as a call to MQDISC commits, which could be surprising.
          # Require the application to always explictly call #commit.
          queue_manager.backout
          queue_manager.disconnect
        end
      end

      queue_manager
    end

    # Open the specified queue, then close it once the
    # supplied code block has completed
    #
    # Parameters:
    # * Since the number of parameters can vary dramatically, all parameters are passed by name in a hash
    # * See Queue.open for the complete list of parameters, except that :queue_manager is *not* required
    #   since it is supplied automatically by this method
    #
    # Example:
    #   require 'wmq/wmq_client'
    #
    #   WMQ::QueueManager.connect(q_mgr_name: 'REID', connection_name: 'localhost(1414)') do |qmgr|
    #     qmgr.open_queue(q_name: 'TEST.QUEUE', mode: :output) do |queue|
    #       queue.put(data: 'Hello World')
    #     end
    #   end
    def open_queue(**opts, &block)
      WMQ::Queue.open(**opts, queue_manager: self, &block)
    end

    # Execute any MQSC command against the queue manager
    #
    # Example
    #   require 'wmq/wmq'
    #   require 'wmq/wmq_const_admin'
    #   WMQ::QueueManager.connect(q_mgr_name: 'REID', connection_name: 'localhost(1414)') do |qmgr|
    #     qmgr.mqsc('dis ql(*)').each {|item| p item }
    #   end
    def mqsc(mqsc_text)
      execute(command: :escape, escape_type: WMQ::MQET_MQSC, escape_text: mqsc_text).collect { |item| item[:escape_text] }
    end

    # Put a reply message back to the sender
    #
    #   The :message is sent to the queue and queue manager specified in the
    #   :reply_to_q and :reply_to_q_mgr propoerties of the :request_message.
    #
    #   The following rules are followed before sending the reply:
    #   - Only send replies to Request messages. No reply for Datagrams
    #   - Set the message type to Reply when replying to a request message
    #   - Reply with:
    #     - Remaining Expiry (Ideally deduct any processing time since get)
    #     - Same priority as received message
    #     - Same persistence as received message
    #   - Adhere to the Report options supplied for message and correlation id's
    #       in reply message
    #   - All headers must be returned on reply messages
    #     - This allows the calling application to store state information
    #       in these headers
    #     - Unless of course if the relevant header is input only and used
    #       for completing the request
    #       - In this case any remaining headers should be returned
    #         to the caller
    #
    # Parameters:
    #   * :request_message The message originally received
    #   * All the other parameters are the same as QueueManager#put
    #
    def put_to_reply_q(parms)
      # Send replies only if message type is request
      if parms[:request_message].descriptor[:msg_type] == WMQ::MQMT_REQUEST
        request = parms.delete(:request_message)

        reply                         = parms[:message] ||= Message.new(data: parms[:data])
        reply.descriptor[:msg_type]   = WMQ::MQMT_REPLY
        reply.descriptor[:expiry]     = request.descriptor[:expiry]
        reply.descriptor[:priority]   = request.descriptor[:priority]
        reply.descriptor[:persistence]= request.descriptor[:persistence]
        reply.descriptor[:format]     = request.descriptor[:format]

        # Set Correlation Id based on report options supplied
        reply.descriptor[:correl_id]  =
          if request.descriptor[:report] & WMQ::MQRO_PASS_CORREL_ID != 0
            request.descriptor[:correl_id]
          else
            request.descriptor[:msg_id]
          end

        # Set Message Id based on report options supplied
        if request.descriptor[:report] & WMQ::MQRO_PASS_MSG_ID != 0
          reply.descriptor[:msg_id] = request.descriptor[:msg_id]
        end

        q_name = {
            q_name:     request.descriptor[:reply_to_q],
            q_mgr_name: request.descriptor[:reply_to_q_mgr]
        }

        parms[:q_name] = q_name
        put(parms)
      else
        false
      end
    end

    # Put a message to the Dead Letter Queue
    #
    #   If an error occurs when processing a datagram message
    #   it is necessary to move the message to the dead letter queue.
    #   I.e. An error message cannot be sent back to the sender because
    #        the original message was not a request message.
    #          I.e. msg_type != WMQ::MQMT_REQUEST
    #
    #   All existing message data, message descriptor and message headers
    #   are retained.
    #
    def put_to_dead_letter_q(parms)
      message = parms[:message] ||= Message.new(data: parms[:data])
      dlh     = {
        header_type:     :dead_letter_header,
        reason:          parms.delete(:reason),
        dest_q_name:     parms.delete(:q_name),
        dest_q_mgr_name: name
      }

      message.headers.unshift(dlh)
      parms[:q_name] = 'SYSTEM.DEAD.LETTER.QUEUE' #TODO Should be obtained from QMGR config

      put(parms)
    end

    # Expose Commands directly as Queue Manager methods
    def method_missing(name, *args)
      if args.size == 1
        execute({ command: name }.merge(args[0]))
      elsif args.size == 0
        execute(command: name)
      else
        raise("Invalid arguments supplied to QueueManager#:#{name}, args:#{args}")
      end
    end

  end
end
