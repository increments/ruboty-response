module Ruboty
  module Handlers
    class Response < Base
      NAMESPACE = 'response'

      on /(?<keyword>.+)/, name: 'catchall', hidden: true, all: true

      on /add response \/(?<regex>.+)\/ (?<response>`?.+`?)/, name: 'add', description: 'Add a response'
      on /delete response (?<id>.+)/, name: 'delete', description: 'Delete a response'
      on /list responses\z/, name: 'list', description: 'Show registered responses'

      def catchall(message)
        responses.each do |id, hash|
          next unless /#{hash[:regex]}/ =~ message[:keyword] rescue false

          # If the response is a code
          if hash[:response] =~ /\A`.+`\z/
            thread = Thread.start do
              result = `#{hash[:response].match(/\A`(?<code>.+)`\z/)[:code]}`.chomp!
              message.reply(result)
            end
            Thread.start do
              sleep 10
              thread.kill
            end
          else
            message.reply(hash[:response])
          end
        end
      end

      def add(message)
        id = generate_id
        hash = {
          regex: message[:regex],
          response: message[:response]
        }

        # Insert to the brain
        responses[id] = hash

        message.reply("Response #{id} is registered.")
      end

      def delete(message)
        if responses.delete(message[:id].to_i)
          message.reply("Response #{message[:id]} is unregistered.")
        else
          message.reply("Response #{message[:id]} is not found.")
        end
      end

      def list(message)
        if responses.empty?
          message.reply('Nothing is registered.')
        else
          response_list = responses.map do |id, hash|
            "#{id}: /#{hash[:regex]}/ -> #{hash[:response]}"
          end.join("\n")
          message.reply(response_list, code: true)
        end
      end

      private

      def responses
        robot.brain.data[NAMESPACE] ||= {}
      end

      def generate_id
        loop do
          id = rand(1000)
          break id unless responses.has_key?(id)
        end
      end
    end
  end
end
