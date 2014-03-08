
Inspired by [DroidLabs Serializer](/droidlabs/active_serializer).

For classes like these:

```ruby
Person = Struct.new(:name, :age, :dogs)
Dog = Struct.new(:name, :age)
```

make a serializer like this:

```ruby
class DogsOwnerSerializer < Serializer
  resource do
    attr :name
    attr :age
    collection :dogs do
      attrs :name, :age
    end
  end
end
```

object tree like this:

```ruby
person = Person.new(
  'Cruella', 44,
  [
    Dog.new('Perdita',0.5),
    Dog.new('Lucky',0.5),
    Dog.new('Rolly',0.5)
  ]
)
```

run:

```ruby
DogsOwnerSerializer.serialize(person).to_json
```

result will look like:

```json
{
  "name": "Cruella",
  "age": 44,
  "dogs":
  [
    {"name": "Perdita", "age": 0.5},
    {"name": "Lucky",   "age": 0.5},
    {"name": "Rolly",   "age": 0.5}
  ]
}
```
