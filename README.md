# Jdec

Flexible json parser and helper function to marshal/unmarshal json into objects.

* Support to all common types
* Date Date iso 8601 support.
* Seq support: 
* Table support: TableRef[string,string] , TableRef[string,T]
* No missing key exception (compared to the json macro: to(JsonNode,T))


### Example usage

```
  type SubNode = ref object of RootObj
    info: string
    data: int

  type BaseEvent = ref object of RootObj
    id :string

  type TestEvent = ref object of BaseEvent
    data : string
    num: int32
    flag: bool
    tref: TableRef[string,string]
    subt: TableRef[string,SubNode]
    date: DateTime
    tags : seq[string]
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
    "tags"  : [ "ptup"],
    "subt"  : {
      "0"  : {
        "info" : "sub_test",
        "data" : 90
      }
    },
    "sub"  : {
      "info" : "test",
      "data" : 90
    }
  }
  """)

  var tr = TestEvent(  date: now())
  var be = BaseEvent()
  expandMacros:
    loadJson(j,tr[],be[])
    loadJson(j.getObj("sub"),tr.sub[])
    echo tr[]
    echo tr.sub[]

```

## TODO
* Add Uri support
* Add more table support
* Add more date format support
