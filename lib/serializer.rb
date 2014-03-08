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

    def collection_add name, v=(v_empty=true), &block
      self[name] += Collection.walk(v_empty ? @_.send(name) : v, &block)
    end

    def collection_of name, attrs, &block
      self[name] = attrs.map do |attr|
        Collection.walk(@_.send(attr), &block)
      end.flatten(1) # flatten one level deep
    end
  end

  class Collection < ::Array
    def self.walk v, &block
      unless block
        # check if the collection is convertible to array
        v.respond_to? :to_a or
          raise 'leaf is not convertible to array (does not respond to :to_a)'
        # just return the array representation of the collection
        return v.to_a
      end

      v.map do |item|
        Resource.walk(item, &block)
      end
    end
  end
end
