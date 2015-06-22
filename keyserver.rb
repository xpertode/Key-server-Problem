require 'socket'
require 'securerandom'
require 'sinatra'
require 'redis'


=begin
  Features
  E1: Generate random keys
  E2: Serve and block a key
  E3: Unblock a key
  E4: Delete a key
  E5: Keep Alive till 5 minutes
  
  Rules
  R1: Unblock a key after 60 sec if not unblocked

  Libraries
  
  Redis
  Expire command
=end



#Server Host and  Port settings
set :bind, '127.0.0.1'
set :port, 2323

#Create redis database
redis = Redis.new

#Call methods corresponding to different requests
#E1
get '/generate' do
     KeyServer.generate(redis)
  end

#E2
get '/get' do
     key = KeyServer.get(redis)
     if key.nil?
       not_found
     else
       key
     end
end

#E3
get '/unblock/:key' do
     KeyServer.unblock(redis,params['key'])
end

#E4
get '/delete/:key' do
    KeyServer.delete(redis,params['key'])
end

#E5
get '/keep_alive/:key' do
    KeyServer.keep_alive(redis,params['key'])
end

#404
not_found do
  '404.Not found'
end


class KeyServer
	def self.generate(redis)
	 rand_key = SecureRandom.hex(20)
         redis.sadd('UNBLOCKED',rand_key)
         redis.setex(rand_key,300,Time.now)
         if rand_key.nil?
            return "Key can't be generated"
         else
            return "Key generated successfully"
         end
        end
      
       #Returns nil if 404
       def self.get(redis)
          key = redis.spop('UNBLOCKED')
          if not key.nil?
                redis.set(key,Time.now) 
                #Move to unblocked after 60 secs
          end
          return key
       end
    
       def self.unblock(redis,key)
           if redis.exists(key)
                if redis.sadd('UNBLOCKED',key)
                   return "Key unblocked successfully."
                else
                   return "Key can't be unblocked"
               end
           else
                   return "No such key exists."
          end
       end

       def self.delete(redis,key)
           if redis.exists(key)
                if redis.del(key)==1
                    if redis.sismember('UNBLOCKED',key)==1
                        redis.srem('UNBLOCKED',key)
                    end
                   return "Key deleted successfully."
                else
                   return "key can't be deleted."
                end
           else 
                   return "No such key exists."
          end
       end

       def self.keep_alive(redis,key)
           if redis.exists(key)
                redis.setex(key,300,Time.now)
                return "TTL updated."
           else
                return "No such key exists."
           end
       end
   
       def self.error
           '404.Not found'
       end
end
