require_relative 'keys'
require 'redis'
require 'timecop'

redis = Redis.new
redis.flushall

describe Keys do
  key = nil
  describe '.generate' do
    it 'should generate key successfully' do
      expect(Keys.generate(redis)).to match(/successfully/)
    end
  end
  
  describe '.get' do
    it 'should return a random key' do
      key = Keys.get(redis)
      expect(key).to match(/[a-f0-9]*/)
    end
  end
  
  describe '.unblock' do
    it 'should return no such key' do
      expect(Keys.unblock(redis,"86cc561f929148ca83159a88f2c7e98c8e78d3e6")).to match(/No such key/)
    end
  end
  
  describe '.unblock' do
    it 'should return unblocked successfully' do
      expect(Keys.unblock(redis,key)).to match(/successfully/)
    end
  end
  
  describe '.unblock' do
    it 'should return already unblocked' do
      expect(Keys.unblock(redis,key)).to match(/already/)
    end
  end
  
  describe '.delete' do
    it 'should return no such key' do
      expect(Keys.delete(redis,"86cc561f929148ca83159a88f2c7e98c8e73e6")).to match(/No such key/)
    end
  end
  
  describe '.delete' do
    it 'should return deleted successfully' do
      expect(Keys.delete(redis,key)).to match(/successfully/)
    end
  end
  
  describe '.unblock' do
    it 'should return no such key' do
      expect(Keys.unblock(redis,key)).to match(/No such key/)
    end
  end
  
  
  
  
  describe '.generate' do
    it 'should generate key successfully' do
      expect(Keys.generate(redis)).to match(/successfully/)
    end
  end
  
  describe '.get' do
    it 'should return a random key' do
      key = Keys.get(redis)
      expect(key).to match(/^[a-f0-9]*$/)
    end
  end
  
  describe '.get' do
    it 'should return the $key' do
      time_now=Time.now()
      Timecop.travel(time_now+60)
      dup_key = Keys.get(redis)
      expect(dup_key).to eq(key)
    end
  end
  
  describe '.unblock' do
    it 'should return unblocked successfully' do
      expect(Keys.unblock(redis,key)).to match(/successfully/)
    end
  end
  
  describe '.keep_alive' do
    it 'should return TTL updated' do
      expect(Keys.keep_alive(redis,key)).to match(/kept alive/)
    end
  end
  
end
    
