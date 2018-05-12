# Jdec

Flexible json parser and helper to marshal/unmarshal json into objects.

* Support to all common types
* Date Date iso 8601 support.
* Seq support: seq[string], seq[int], seq[T]
* Table support: TableRef[string,string], TableRef[string,T]
* No missing key exception (compared to the json macro: to(JsonNode,T))


### Example usage

```
  type BaseEvent = ref object of RootObj
    id :string

  type SubNode = ref object of BaseEvent
    info: string
    data: int

  type TestEvent = ref object of BaseEvent
    data : string
    num: int32
    flag: bool
    tref: TableRef[string,string]
    subt: TableRef[string,SubNode]
    date: DateTime
    tags : seq[string]
    nodes : seq[SubNode]
    nums : seq[int8]
    sub: SubNode


  var j = parseJson("""
  {
    "id" : "whatauniqueid",
    "data" : "somerandomAsdatra",
    "num" :  18293,
    "tref" : {
      "t" : "Test"
    },
    "flag" : true,
    "date" : "2018-05-10T09:49:18-12:00",
    "nums" : [3,3,12,35,64,12],
    "tags"  : [ "tag1" , "tag2", "asds"],
    "subt"  : {
      "test"  : {
        "id" : "sub2",
        "info" : "sub_test",
        "data" : 90
      },
      "super1"  : {
        "data" : 102
      },
      "otherkey": {}
    },
    "nodes" : [
      {
        "info" : "test",
        "data" : 90
      }
    ],
    "sub"  : {
      "info" : "test",
      "data" : 90
    }
  }
  """)

  var tr = TestEvent(  date: now())
  tr.subt = newTable[string,SubNode]()
  var be = BaseEvent()

  # Load base object and ref attributes too
  loadJson(j,tr[],be[])
  # Load sub object
  loadJson(j.getObj("sub"),tr.sub[])
  # Load table of objects SubNode type
  loadTable(j,tr.subt,"subt",SubNode,be[])
  # Load array of objects
  loadArray(j,tr.nodes,"nodes",SubNode,be[])

  echo tr[]
  echo tr.sub[]
  for k,s in tr.nodes:
    echo "node"
    echo s[]

  for k,s in tr.subt:
    echo "subt"
    echo s[]

```

## TODO
* Improve API
* Add Uri support
* Add more table support
* Add more date format support
