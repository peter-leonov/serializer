require 'serializer'

Parents = Struct.new(:mom,:dad)
Person = Struct.new(:name, :age, :dogs, :cats)
Dog = Struct.new(:name, :age)
Cat = Struct.new(:name, :age)


describe Serializer do

  describe '.resource' do
    it 'should convert to hash' do
      class JustAResource < Serializer
        resource
      end

      JustAResource.serialize(
        Person.new('John', 20)
      ).should == {
        name: "John",
        age: 20,
        cats: nil,
        dogs: nil
      }
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

      it 'should get the value form block if given' do
        class AttrWithBlock < Serializer
          resource do |obj|
            attr :age do
              123
            end
            attr :nick, obj.name do |name|
              name.upcase
            end
          end
          self
        end.serialize(
          Person.new('John', 20)
        ).should == {
          age: 123,
          nick: "JOHN"
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
            resource :dogs
          end
        end
        ResourceWithResource.serialize(
          Person.new(
            'John', 33,
            Dog.new('Spike', 7)
          )
        ).should == {
          name: "John",
          dogs: {name: "Spike", age: 7}
        }
      end
      
      it 'allows nested resources with custom attributes set' do
        class ResourceWithResourceBlock < Serializer
          resource do |obj|
            attr :name
            resource :dogs do |dog|
              attr :name
              attr :age, dog.age + 1
            end
          end
        end

        ResourceWithResourceBlock.serialize(
          Person.new(
            'John', 33,
            Dog.new('Spike', 7)
          )
        ).should == {
          name: "John",
          dogs: {age: 8, name: "Spike"}
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
            Person.new(
              'Cruella', 44,
              [
                Dog.new('Perdita', 0.5),
                Dog.new('Lucky', 0.5),
                Dog.new('Rolly', 0.5)
              ]
            )
          ).should == {
            name: 'Cruella',
            dogs: [
              {name: 'Perdita', age: 0.5},
              {name: 'Lucky', age: 0.5},
              {name: 'Rolly', age: 0.5}
            ]
          }
        end
      end

      describe '#namespace' do
        it 'adds a wrapping hash with same def object' do
          class NamespaceInAResource < Serializer
            resource do
              namespace :ns do |person|
                attr :name
                attr :age, person.age
              end
            end
            self
          end.serialize(
            Person.new(
              'Cruella', 44,
            )
          ).should == {
            ns: {
              name: 'Cruella',
              age: 44
            }
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
            Person.new(
              'Me', 26,
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
        it 'should convert to array of hashes' do
          class JustACollection < Serializer
            collection
          end

          JustACollection.serialize(
            Parents.new(Person.new('Dad', 50), Person.new('Mom', 46))
          ).should == [
            {name: 'Dad', age: 50, dogs: nil, cats: nil},
            {name: 'Mom', age: 46, dogs: nil, cats: nil}
          ]
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

    describe Serializer::List do

      describe '.walk' do
        it 'should convert to array' do
          class JustAList < Serializer
            list
          end

          JustAList.serialize(
            Parents.new('Mom', 'Dad')
          ).should == [
            'Mom',
            'Dad'
          ]
        end

        it 'should map the array if block given' do
          class ListWithBlock < Serializer
            list do |item|
              resource do
                attr :name
                attr :age, item.age
              end
            end
          end

          ListWithBlock.serialize(
            Parents.new(Person.new('Dad', 50), Person.new('Mom', 46))
          ).should == [
            {name: 'Dad', age: 50},
            {name: 'Mom', age: 46}
          ]
        end

        it 'should list lists' do
          class ListOfLists < Serializer
            list do
              list do
                _
              end
            end
          end

          ListOfLists.serialize(
            Parents.new(Person.new('Dad', 50), Person.new('Mom', 46))
          ).should == [
            ['Dad', 50, nil, nil],
            ['Mom', 46, nil, nil]
          ]
        end

        it 'should list collections' do
          class ListOfCollections < Serializer
            list do
              collection do
                attr :name
                attr :age, _.age - 50
              end
            end
            self
          end.serialize(
            Parents.new(
              Parents.new(Person.new('Grand Dad', 75), Person.new('Grand Mom', 70)),
              Parents.new(Person.new('Grand Dad', 50), Person.new('Grand Mom', 46)) # young ones :)
            )
          ).should == [
            [{name: 'Grand Dad', age: 25}, {name: 'Grand Mom', age: 20}],
            [{name: 'Grand Dad', age: 0}, {name: 'Grand Mom', age: -4}] # hee-hee :)
          ]
        end
      end
    end
  end

end