import json, jdec

var s = newJsonSchema()

s.addField "name"
s.addField "age"
s.addField "test"

let jstring = """{ "name" : "Diego", "age" : 23, "test" : "restset" , "extra": true}
"""

let j = parseJson(jstring)

echo j.valid(s)


