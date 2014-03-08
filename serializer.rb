#!ruby
require 'oj'

class Serializer
  def self.serialize v
    raise 'no root rule defined' unless @class
    # return anything the walk method returns
    @class.walk(v, &@block)
  end
  def self.hash &block
    @class = Hash
    @block = block
  end
  
  class Hash < ::Hash
    def self.walk v, &block
      unless block
        # check if the leaf is convertible to hash
        v.respond_to? :to_h or
          raise 'leaf is not convertible to hash (does not respond to :to_h), supply a block with appropriate rules'
        # just return the hash representation of the leaf
        return v.to_h
      end
      
      hash = new(v)
      hash.instance_exec(v, &block)
      hash
    end

    def initialize v
      # default object, aka leaf
      @_ = v
    end

    def attr name, v=(v_empty=true)
      self[name] = v_empty ? @_.send(name) : v
    end

    def attrs *names
      names.each do |name|
        attr name
      end
    end

    def hash name, v=(v_empty=true), &block
      self[name] = self.class.walk(v_empty ? @_.send(name) : v, &block)
    end
  end
end



# tests


Person = Struct.new(:name, :age)

class JustAHash < Serializer
  hash
end
puts Oj.dump(JustAHash.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})
puts Oj.dump(JustAHash.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})


class HashWithAttrs < Serializer
  hash do |obj|
    attr :age
    attr :name
    attr :nick, obj.name.upcase
    attr :hobby, 'arts'
  end
end
puts Oj.dump(HashWithAttrs.serialize(Person.new('John', 20))) == Oj.dump({age: 20, name: "John", nick: "JOHN", hobby: "arts"})

class HashWithManyAttrs < Serializer
  hash do |obj|
    attrs :name, :age
  end
end
puts Oj.dump(HashWithManyAttrs.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})

DogOwner = Struct.new(:name, :dog)
Dog = Struct.new(:name, :age)
class HashWithHash < Serializer
  hash do |obj|
    attr :name
    hash :dog
  end
end
puts Oj.dump(HashWithHash.serialize(DogOwner.new('John', Dog.new('Spike', 7)))) == Oj.dump({name: "John", dog: {name: "Spike", age: 7}})
class HashWithHashBlock < Serializer
  hash do |obj|
    attr :name
    hash :dog do |dog|
      # different order
      attr :age, dog.age
      attr :name
    end
  end
end
puts Oj.dump(HashWithHashBlock.serialize(DogOwner.new('John', Dog.new('Spike', 7)))) == Oj.dump({name: "John", dog: {age: 7, name: "Spike"}})
