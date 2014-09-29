require 'sinatra/base'

class TestApp < Sinatra::Base
  get '/' do
    "test app"
  end
end
