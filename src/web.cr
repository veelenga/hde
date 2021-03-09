require "kemal"
require "./app"

get "/" do |env|
  render "src/views/index.ecr", "src/views/layouts/application.ecr"
end

ws "/ws" do |socket|
  socket.on_message do |message|
    App.new.process(message) do |cmd, text|
      socket.send("#{cmd} > #{text}")
    end
  end

  socket.on_close do
    puts "Closing socket"
  end
end

Kemal.run
