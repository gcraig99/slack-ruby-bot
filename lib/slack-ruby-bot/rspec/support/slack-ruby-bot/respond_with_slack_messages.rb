require 'rspec/expectations'
RSpec::Matchers.define :respond_with_slack_messages do |expected|
  match do |actual|
    raise ArgumentError, 'respond_with_slack_messages expects an array of ordered responses' unless expected.is_a? Array
    client = respond_to?(:client) ? send(:client) : SlackRubyBot::Client.new
    def client.test_messages
      @test_received_messages
    end

    def client.say(options = {})
      super
      @test_received_messages = @test_received_messages.nil? ? '' : @test_received_messages
      @test_received_messages += "#{options.inspect}\n"
    end

    message_command = SlackRubyBot::Hooks::Message.new
    channel, user, message = parse(actual)

    allow(Giphy).to receive(:random) if defined?(Giphy)

    allow(client).to receive(:message)
    message_command.call(client, Hashie::Mash.new(text: message, channel: channel, user: user))
    @messages = client.test_messages
    expected.each do |exp|
      expect(client).to have_received(:message).with(channel: channel, text: exp).once
    end
    true
  end
  failure_message do |_actual|
    message = "expected to receive messages in order with text: #{expected.join("\n")} got: #{@messages}"
    message
  end

private

  def parse(actual)
    actual = { message: actual } unless actual.is_a?(Hash)
    [actual[:channel] || 'channel', actual[:user] || 'user', actual[:message]]
  end
end
