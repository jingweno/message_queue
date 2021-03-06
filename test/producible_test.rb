require_relative "test_helper"

class ProducibleTest < Test::Unit::TestCase
  class Producer
    include MessageQueue::Producible
  end

  def setup
    MessageQueue.connect(:adapter => :bunny, :serializer => :plain)
  end

  def teardown
    MessageQueue.disconnect
  end

  def test_producible
    Producer.exchange :name => "test_producible", :type => :direct, :auto_delete => true
    Producer.message :routing_key => "test_producible"

    assert_equal "test_producible", Producer.exchange_options[:name]
    assert_equal :direct, Producer.exchange_options[:type]
    assert_equal "test_producible",  Producer.message_options[:routing_key]

    producer = Producer.new

    ch = MessageQueue.connection.connection.create_channel
    queue = ch.queue("test_producible", :auto_delete => true).bind("test_producible", :routing_key => "test_producible")

    @payload = nil
    queue.subscribe do |_, _, payload|
      @payload = payload
    end

    msg = Time.now.to_s
    producer.publish msg

    sleep 1

    assert_equal msg, @payload
  end
end
