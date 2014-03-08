#!ruby
require 'oj'

class Serializer
  def self.serialize v
    raise 'no root rule defined' unless @class
    # return anything the walk method returns
    @class.walk(v, &@block)
  end

  def self.resource &block
    raise 'root rule is already defined' if @class
    @class = Resource
    @block = block
  end
  def self.collection &block
    raise 'root rule is already defined' if @class
    @class = Collection
    @block = block
  end

  class Resource < ::Hash
    def self.walk v, &block
      unless block
        # check if the resource is convertible to hash
        v.respond_to? :to_h or
          raise 'resource is not convertible to hash (does not respond to :to_h), supply a block with appropriate rules'
        # just return the hash representation of the resource
        return v.to_h
      end
      
      resource = new(v)
      resource.instance_exec(v, &block)
      resource
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

    def resource name, v=(v_empty=true), &block
      self[name] = Resource.walk(v_empty ? @_.send(name) : v, &block)
    end

    def collection name, v=(v_empty=true), &block
      self[name] = Collection.walk(v_empty ? @_.send(name) : v, &block)
    end
  end

  class Collection < ::Array
    def self.walk v, &block
      unless block
        # check if the leaf is convertible to array
        v.respond_to? :to_a or
          raise 'leaf is not convertible to array (does not respond to :to_a)'
        # just return the array representation of the leaf
        return v.to_a
      end

      v.map do |item|
        Resource.walk(item, &block)
      end
    end
  end
end



# tests


Person = Struct.new(:name, :age)

class JustAResource < Serializer
  resource
end
puts Oj.dump(JustAResource.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})
puts Oj.dump(JustAResource.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})


class ResourceWithAttrs < Serializer
  resource do |obj|
    attr :age
    attr :name
    attr :nick, obj.name.upcase
    attr :hobby, 'arts'
  end
end
puts Oj.dump(ResourceWithAttrs.serialize(Person.new('John', 20))) == Oj.dump({age: 20, name: "John", nick: "JOHN", hobby: "arts"})

class ResourceWithManyAttrs < Serializer
  resource do |obj|
    attrs :name, :age
  end
end
puts Oj.dump(ResourceWithManyAttrs.serialize(Person.new('John', 20))) == Oj.dump({name: "John", age: 20})

DogOwner = Struct.new(:name, :dog)
Dog = Struct.new(:name, :age)
class ResourceWithResource < Serializer
  resource do |obj|
    attr :name
    resource :dog
  end
end
puts Oj.dump(ResourceWithResource.serialize(DogOwner.new('John', Dog.new('Spike', 7)))) == Oj.dump({name: "John", dog: {name: "Spike", age: 7}})
class ResourceWithResourceBlock < Serializer
  resource do |obj|
    attr :name
    resource :dog do |dog|
      # different order
      attr :age, dog.age
      attr :name
    end
  end
end
puts Oj.dump(ResourceWithResourceBlock.serialize(DogOwner.new('John', Dog.new('Spike', 7)))) == Oj.dump({name: "John", dog: {age: 7, name: "Spike"}})


class JustACollection < Serializer
  collection
end
puts Oj.dump(JustACollection.serialize(Struct.new(:a,:b,:c).new(1,2,3))) == Oj.dump([1,2,3])

class CollectionOfDogs < Serializer
  collection do |dog|
    attr :name
    attr :age, dog.age
  end
end
puts Oj.dump(CollectionOfDogs.serialize([Dog.new('Spike',7),Dog.new('Scooby',13),Dog.new('Bear',1)])) == Oj.dump([{name:'Spike',age:7},{name:'Scooby',age:13},{name:'Bear',age:1}])

DogsOwner = Struct.new(:name, :dogs)
class CollectionInAResource < Serializer
  resource do
    attr :name
    collection :dogs do
      attrs :name, :age
    end
  end
end
puts Oj.dump(CollectionInAResource.serialize(DogsOwner.new('Cruella', [Dog.new('Perdita',0.5),Dog.new('Lucky',0.5),Dog.new('Rolly',0.5)]))) == Oj.dump({name:'Cruella', dogs:[{name:'Perdita',age:0.5},{name:'Lucky',age:0.5},{name:'Rolly',age:0.5}]})
