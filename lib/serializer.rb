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
  def self.list &block
    raise 'root rule is already defined' if @class
    @class = List
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

    # default object, aka leaf
    attr_accessor :_

    def initialize v
      # set the leaf
      @_ = v
    end

    def attr name, v=(v_empty=true)
      if block_given?
        v = yield v
        v_empty = false
      end
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

    def namespace name, &block
      self[name] = Resource.walk(@_, &block)
    end

    def collection name, v=(v_empty=true), &block
      self[name] = Collection.walk(v_empty ? @_.send(name) : v, &block)
    end

    def collection_add name, v=(v_empty=true), &block
      self[name] += Collection.walk(v_empty ? @_.send(name) : v, &block)
    end

    def collection_of name, attrs, &block
      self[name] = attrs.map do |attr|
        Collection.walk(@_.send(attr), &block)
      end.flatten(1) # flatten one level deep
    end

    def list name, v=(v_empty=true), &block
      self[name] = List.walk(v_empty ? @_.send(name) : v, &block)
    end
  end

  class Collection < ::Array
    def self.walk v, &block
      unless block
        # check if the collection is enumerable
        v.is_a? Enumerable or
          raise 'collection is not enumerable (does not inherit Enumerable)'
        # pretend that the collection is an array of resources
        return v.map { |item| Resource.walk(item) }
      end

      v.map do |item|
        Resource.walk(item, &block)
      end
    end
  end

  class List < ::Array
    def self.walk v, &block
      # check if the collection is enumerable
      v.is_a? Enumerable or raise 'list is not enumerable (does not inherit Enumerable)'

      unless block
        # pretend that the collection is an array of anything
        return v.to_a
      end

      list = new
      v.map do |item, *args|
        list._ = item # in case of array-like list
        list.instance_exec(item, *args, &block)
      end
    end

    # default object, aka leaf
    attr_accessor :_

    def resource v=(v_empty=true), &block
      Resource.walk(v_empty ? @_ : v, &block)
    end

    def collection v=(v_empty=true), &block
      Collection.walk(v_empty ? @_ : v, &block)
    end

    def list v=(v_empty=true), &block
      List.walk(v_empty ? @_ : v, &block)
    end
  end
end
