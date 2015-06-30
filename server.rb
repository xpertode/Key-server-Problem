require 'sinatra'
require 'redis'
require_relative 'settings'
require_relative 'keys'

class Server < Sinatra::Base
  include Settings
  #Server Host and  Port settings
  set :bind, Settings::HOST
  set :port, Settings::PORT

  #Create redis database
  redis = Redis.new

  #Call methods corresponding to different requests
  #E1
  get '/generate' do
    Keys.generate(redis)
  end

  #E2
  get '/get' do
    key = Keys.get(redis)
    if key.nil?
      "404 Not Found"
    else
      key
    end
  end

  #E3
  get '/unblock/:key' do
    Keys.unblock(redis,params['key'])
  end

  #E4
  get '/delete/:key' do
    Keys.delete(redis,params['key'])
  end

  #E5
  get '/keep_alive/:key' do
    Keys.keep_alive(redis,params['key'])
  end


  not_found do
    'Bad Request'
  end
  
end