require 'socket'
require 'securerandom'
require 'sinatra'
require 'redis'
require 'time'

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
       "404 Not Found"
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


not_found do
  'Bad Request'
end


class KeyServer
  
  TIME_TO_LIVE = 300 #secs
  T_EXPIRE = 60  #secs
  KEY_LENGTH = 20

  #E1
  class << self 
  def generate(redis)
    
    rand_key = self.get_random_hex(KEY_LENGTH)
    
    #Add key to set of free keys
    self.add_available_key(redis,rand_key)
    
    #Set time_to_live
    self.set_exp(redis,rand_key,TIME_TO_LIVE)
    
    if rand_key.nil?
        return "Key can't be generated"
    else
        return "Key generated successfully."
    end
  end
  
  #E2    
  #Returns nil if 404
  def get(redis)
      key = self.get_available_key(redis)
      if not key.nil?
        #Set the time stamp for the key
        self.mark_time(redis,key)
        self.add_blocked_key(redis,key)
        return key     
      else 
        key = self.get_expired_key(redis)
        return key     
      end
      return nil
  end
   
   #E3 
   def unblock(redis,key)
      if redis.exists(key)     
            if  self.add_available_key(redis,key)
                self.remove_blocked_key(redis,key) 
                return "Key unblocked successfully."
            else
                return "Key already unblocked."
            end
      else
          return "No such key exists."
      end
    end

    #E4
    def delete(redis,key)
       if redis.exists(key)
            if redis.del(key)==1
                  self.remove_unblocked_key(redis,key)
                  self.remove_blocked_key(redis,key) 
                  return "Key deleted successfully."
            else
                  return "key can't be deleted."
            end
        else 
            return "No such key exists."
        end
      end

      #E5
       def keep_alive(redis,key)
           if redis.exists(key)
                self.set_exp(redis,key,300)
                return "Key will be kept alive for 5 more minutes."
           else
                return "No such key exists."
           end
       end

    #Helper Functions
     def get_random_hex(len)
        SecureRandom.hex(len)
    end
    
    def add_available_key(redis,key)
      redis.sadd('UNBLOCKED',key)
    end
    
    def set_exp(redis,key,t_expire)
      redis.setex(key,t_expire,Time.now)
    end
    
    def get_available_key(redis)
      redis.spop('UNBLOCKED')
    end

    def mark_time(redis,key)
      redis.set(key,Time.now)
    end

    def add_blocked_key(redis,key)
      redis.lpush('BLOCKED',key)
    end

    def get_blocked_key(redis)
      redis.rpop('BLOCKED')
    end

    def get_init_time(redis,key)
      redis.get(key)
    end

    def put_blocked_key(redis,key)
      redis.rpush('BLOCKED',key)
    end

    def remove_blocked_key(redis,key)
      redis.lrem('BLOCKED',1,key)
    end
    
    def remove_unblocked_key(redis,key)
      if redis.sismember('UNBLOCKED',key)
            redis.srem('UNBLOCKED',key)
      end
    end
    
    def get_expired_key(redis)
      key = self.get_blocked_key(redis)
      if not key.nil?
          time_stamp = self.get_init_time(redis,key)
          if (Time.parse(time_stamp)-Time.now).abs >=T_EXPIRE
            self.add_blocked_key(redis,key)
            self.mark_time(redis,key)
            return key
          else
            self.put_blocked_key(redis,key)
            return nil
          end
      end 
      return nil     
    end
  end
end
