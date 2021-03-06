require_relative "test_helper"

class MessageQueueTest < Test::Unit::TestCase
  def test_load_adapter
    adapter = MessageQueue.load_adapter(:bunny)
    assert_equal "MessageQueue::Adapters::Bunny", adapter.name

    adapter = MessageQueue.load_adapter(:foo)
    assert_nil adapter
  end

  def test_load_serializer
    serializer = MessageQueue.load_serializer(:message_pack)
    assert_equal "MessageQueue::Serializers::MessagePack", serializer.name

    serializer = MessageQueue.load_serializer(:foo)
    assert_nil serializer
  end

  def test_new_connection
    assert_raises RuntimeError do
      MessageQueue.new_connection(:adapter => :foo)
    end

    connection = MessageQueue.new_connection(:adapter => :bunny,
                                             :serializer => :message_pack,
                                             :uri => "amqp://user:pass@host/vhost")
    assert_equal "MessageQueue::Adapters::Bunny::Connection", connection.class.to_s
  end

  def test_connection
    config_file = File.join File.expand_path(File.dirname(__FILE__)), "support", "message_queue.yml"
    MessageQueue.connect(config_file)

    assert_equal "bunny", MessageQueue.settings[:adapter]
    assert_equal "json", MessageQueue.settings[:serializer]
    assert MessageQueue.connected?

    connection = MessageQueue.connection
    assert_equal "MessageQueue::Adapters::Bunny::Connection", connection.class.to_s

    result = MessageQueue.disconnect
    assert result
    assert !MessageQueue.connected?
    assert_nil MessageQueue.connection

    MessageQueue.reconnect
    assert MessageQueue.connected?

    MessageQueue.disconnect
  end
end
