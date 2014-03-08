require 'serializer'

Person = Struct.new(:name, :age)
DogOwner = Struct.new(:name, :dog)
Dog = Struct.new(:name, :age)
Collection = Struct.new(:a,:b,:c)
DogsOwner = Struct.new(:name, :dogs)
PetsOwner = Struct.new(:name, :dogs, :cats)
Cat = Struct.new(:name, :age)

describe Serializer do

  describe '.resource' do
    it 'should convert to hash' do
      class JustAResource < Serializer
        resource
      end
    
      JustAResource.serialize(Person.new('John', 20)).should == {name: "John", age: 20}
    end
  end
  
  describe Serializer::Resource do

    describe '#attr' do
      it 'should add attibute with or without value' do
        class ResourceWithAttrs < Serializer
          resource do |obj|
            attr :age
            attr :name
            attr :nick, obj.name.upcase
            attr :hobby, 'arts'
          end
        end
        ResourceWithAttrs.serialize(
          Person.new('John', 20)
        ).should == {
          age: 20,
          name: "John",
          nick: "JOHN",
          hobby: "arts"
        }
      end
    end

    describe '#attrs' do
      it 'should add multiple attributes' do
        class ResourceWithManyAttrs < Serializer
          resource do |obj|
            attrs :name, :age
          end
        end
        ResourceWithManyAttrs.serialize(
          Person.new('John', 20)
        ).should == {
          name: "John", age: 20
        }
      end
    end

    describe '#resource' do
      it 'allows nesting resources' do
        class ResourceWithResource < Serializer
          resource do |obj|
            attr :name
            resource :dog
          end
        end
        ResourceWithResource.serialize(
          DogOwner.new(
            'John',
            Dog.new('Spike', 7)
          )
        ).should == {
          name: "John",
          dog: {name: "Spike", age: 7}
        }
      end
      
      it 'allows nested resources with custom attributes set' do
        class ResourceWithResourceBlock < Serializer
          resource do |obj|
            attr :name
            resource :dog do |dog|
              attr :name
              attr :age, dog.age + 1
            end
          end
        end

        ResourceWithResourceBlock.serialize(
          DogOwner.new(
            'John',
            Dog.new('Spike', 7)
          )
        ).should == {
          name: "John",
          dog: {age: 8, name: "Spike"}
        }
      end
      
      describe '#collection' do
        it 'adds an array of hashes' do
          class CollectionInAResource < Serializer
            resource do
              attr :name
              collection :dogs do
                attrs :name, :age
              end
            end
          end

          CollectionInAResource.serialize(
            DogsOwner.new(
              'Cruella',
              [
                Dog.new('Perdita',0.5),
                Dog.new('Lucky',0.5),
                Dog.new('Rolly',0.5)
              ]
            )
          ).should == {
            name: 'Cruella',
            dogs: [
              {name: 'Perdita', age: 0.5},
              {name: 'Lucky', age:0.5},
              {name: 'Rolly', age:0.5}
            ]
          }
        end
      end
      
      describe '#collection_of' do
        it 'adds items to an existing array attribute' do
          class CollectionAndCollectionInAResource < Serializer
            resource do
              attr :name
              collection_of :pets, [:dogs, :cats] do
                attrs :name, :age
              end
            end
          end

          CollectionAndCollectionInAResource.serialize(
            PetsOwner.new(
              'We',
              [
                Dog.new('Dow', 11),
                Dog.new('Katrin', 2),
                Dog.new('Indiana', 3)
              ],
              [
                Cat.new('Baloon', 4)
              ]
            )
          ) == {
            name: 'We',
            pets: [
              {name: 'Dow', age: 11},
              {name: 'Katrin', age: 2},
              {name: 'Indiana', age: 3},
              {name: 'Baloon', age: 4}
            ]
          }
        end
      end
    end

    describe Serializer::Collection do

      describe '.collection' do
        it 'should convert to array' do
          class JustACollection < Serializer
            collection
          end

          JustACollection.serialize(Collection.new(1,2,3)).should == [1,2,3]
        end

        it 'maps items to hashes' do
          class CollectionOfDogs < Serializer
            collection do |dog|
              attr :name
              attr :age, dog.age
            end
          end

          CollectionOfDogs.serialize(
            [
              Dog.new('Spike', 7),
              Dog.new('Scooby', 13),
              Dog.new('Bear', 1)
            ]
          ).should == (
            [
              {name: 'Spike', age: 7},
              {name: 'Scooby', age: 13},
              {name: 'Bear', age: 1}
            ]
          )
        end
      end
    end
  end

end