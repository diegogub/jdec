# jdec
# Copyright Diego Guraieb
# easy json helpers to marshal and unmarshal json
import macros, json, tables, times, options


type
  JsonCheck* = enum
    ValidJson
    MissingField
    InvalidField

const
  dateISO8601* = "yyyy-MM-dd'T'HH:mm:sszzz"
  dateSpaceISO8601* = "yyyy-MM-dd HH:mm:sszzz"


let defaultTimezone* = utc()

proc `%`*[T](t :TableRef[string,T]) : JsonNode =
  result = newJObject()
  for k , s in t.pairs():
    result[k] = %s

proc `%`*[T](t :OrderedTableRef[string,T]) : JsonNode =
  result = newJObject()
  for k , s in t.pairs():
    result[k] = %s

proc `%`*(t :DateTime) : JsonNode =
  result = newJString(t.format(dateISO8601))

proc `%`*[T](o :Option[T]) : JsonNode =
  if o.isSome():
    result = %o.some()
  else:
    result = newJNull()

proc getInt*(n: JsonNode; key: string): int64 =
  if n.hasKey(key):
    return n[key].getInt()
  else:
    return 0

proc getObj*(n: JsonNode; key: string): JsonNode =
  if n.hasKey(key):
    return n[key]
  else:
    return newJObject()

proc getDate*(n: JsonNode; key, format: string): DateTime =
  if n.hasKey(key):
    return parse(n[key].getStr(),format,defaultTimezone)
  else:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, defaultTimezone)

proc getBool*(n: JsonNode; key: string): bool =
  if n.hasKey(key):
    return n[key].getBool()
  else:
    return false

proc getArrayStr*(n: JsonNode; key: string): seq[string] =
  result = newSeq[string](0)
  if n.hasKey(key):
    let nodes = n[key].getElems()
    for node in nodes:
      result.add(node.getStr())

proc getArrayInt*(n: JsonNode; key: string): seq[int64] =
  result = newSeq[int64](0)
  if n.hasKey(key):
    let nodes = n[key].getElems()
    for node in nodes:
      result.add(node.getInt())

proc getArray*(n: JsonNode; key: string): seq[JsonNode] =
  result = newSeq[JsonNode](0)
  if n.hasKey(key):
    let nodes = n[key].getElems()
    for node in nodes:
      result.add(node)

proc toInt(a :seq[int64]): seq[int] =
  result = newSeq[int](0)
  for n in a:
    result.add(int(n))

proc toInt8(a :seq[int64]): seq[int8] =
  result = newSeq[int8](0)
  for n in a:
    result.add(int8(n))

proc toInt16(a :seq[int64]): seq[int16] =
  result = newSeq[int16](0)
  for n in a:
    result.add(int16(n))

proc toInt32(a :seq[int64]): seq[int32] =
  result = newSeq[int32](0)
  for n in a:
    result.add(int32(n))

proc getOrdTableStr*(n: JsonNode; key: string): OrderedTableRef[string,string] =
  result = newOrderedTable[string,string]()
  if n.hasKey(key) and n[key].kind == JObject:
    let fields = n[key].getFields()
    for k,v in fields:
      result[k] = v.getStr()

proc getTableStr*(n: JsonNode; key: string): TableRef[string,string] =
  result = newTable[string,string]()
  if n.hasKey(key) and n[key].kind == JObject:
    let fields = n[key].getFields()
    for k,v in fields:
      result[k] = v.getStr()

proc getTableJson*(n: JsonNode; key: string): TableRef[string,JsonNode] =
  result = newTable[string,JsonNode]()
  if n.hasKey(key) and n[key].kind == JObject:
    let fields = n[key].getFields()
    for k,v in fields:
      result[k] = v

proc getString*(n: JsonNode; key: string): string =
  if n.hasKey(key):
    return n[key].getStr()
  else:
    return ""

# loadJson, load JsonNode into object, and ref types. Change dateFormat to read any custom time format https://nim-lang.org/docs/times.html#parse,string,string,Timezone
macro loadJson*(j :JsonNode;main :typed; types : varargs[typed]; dateFormat = dateISO8601 ): untyped =
    result = nnkStmtList.newTree()
    types.add(main)
    for t in types:
      var tTypeImpl = t.getTypeImpl
      for child in tTypeImpl.children:
        for vars in child.children:
          case vars.kind:
            of nnkIdentDefs:
              var field = vars[0]
              var ftype = vars[1]
              let field_as_string = $field
              case ftype.kind:
                of nnkSym:
                  case $ftype:
                    of "bool":
                      result.add quote do:
                        `main`.`field` = `j`.getBool(`field_as_string`)
                    of "JsonNode":
                      result.add quote do:
                        `main`.`field` = `j`.getObj(`field_as_string`)
                    of "DateTime":
                      result.add quote do:
                        `main`.`field` = `j`.getDate(`field_as_string`,`dateFormat`)
                    of "int", "int16", "int32", "int64", "uint64":
                      case $ftype:
                        of "int8":
                          result.add quote do:
                            `main`.`field` = int8(`j`.getInt(`field_as_string`))
                        of "int":
                          result.add quote do:
                            `main`.`field` = int(`j`.getInt(`field_as_string`))
                        of "int16":
                          result.add quote do:
                            `main`.`field` = int16(`j`.getInt(`field_as_string`))
                        of "int32":
                          result.add quote do:
                            `main`.`field` = int32(`j`.getInt(`field_as_string`))
                        of "int64":
                          result.add quote do:
                            `main`.`field` = `j`.getInt(`field_as_string`)
                    of "string":
                      result.add quote do:
                        `main`.`field` = `j`.getString(`field_as_string`):
                    else:
                      result.add quote do:
                        `main`.`field` = `ftype`()
                of nnkBracketExpr:
                  var params = newSeq[NimNode](0)
                  for subv in ftype.children:
                    params.add(subv)
                  case $params[0]:
                    of "seq":
                      case $params[1]:
                        of "string":
                          result.add quote do:
                            `main`.`field` = `j`.getArrayStr(`field_as_string`):
                        of "int", "int8", "int16", "int32", "int64", "uint64":
                          case $params[1]:
                            of "int32":
                              result.add quote do:
                                `main`.`field` = toInt32(`j`.getArrayInt(`field_as_string`)):
                            of "int16":
                              result.add quote do:
                                `main`.`field` = toInt16(`j`.getArrayInt(`field_as_string`)):
                            of "int8":
                              result.add quote do:
                                `main`.`field` = toInt8(`j`.getArrayInt(`field_as_string`)):
                            of "int":
                              result.add quote do:
                                `main`.`field` = toInt(`j`.getArrayInt(`field_as_string`)):
                            else:
                              result.add quote do:
                                `main`.`field` = `j`.getArrayInt(`field_as_string`):
                    of "TableRef":
                      case $params[1]:
                        of "string":
                          case $params[2]:
                            of "string":
                              result.add quote do:
                                `main`.`field` = `j`.getTableStr(`field_as_string`):
                            else:
                              continue
                        else:
                          continue
                    of "OrderedTableRef":
                      case $params[1]:
                        of "string":
                          case $params[2]:
                            of "string":
                              result.add quote do:
                                `main`.`field` = `j`.getOrdTableStr(`field_as_string`)
                        else:
                          echo "table index not supported"
                else:
                  echo "invalid"
            else:
              continue

type JsonField* = ref object of RootObj
  mandatory*: bool

type JsonSchema* = ref object of RootObj
  fields*: TableRef[string,JsonField]

proc newJsonSchema*(): JsonSchema =
  result = JsonSchema()
  result.fields = newTable[string,JsonField]()

proc addField*(js :JsonSchema; name :string; fMandatory = false) =
  js.fields[name] = JsonField(mandatory : fMandatory)

proc valid*(j :JsonNode; schema :JsonSchema; strict = true): JsonCheck =
  result = ValidJson
  for key,f in j.pairs():
    if not schema.fields.hasKey(key):
      if strict:
        result = InvalidField

  for key, f in schema.fields:
    if not j.hasKey(key):
      if f.mandatory:
        result = MissingField

# loadTable , load table of objects from JsonNode into TableRef[string,T]
template loadTable*(j :JsonNode; t :typed; key: static[string]; isType : typedesc;isOf : varargs[typed]; tableDateFormat = dateISO8601 ): untyped =
  let nodes = j.getTableJson(key)
  for k, n in nodes.pairs():
    var s = `isType`()
    loadJson(n,s[],isOf,dateFormat = tableDateFormat)
    `t`[k] = s

# loadArray, load array of objects from JsonNode into seq[T]
template loadArray*(j :JsonNode; t :typed; key: static[string]; isType : typedesc;isOf : varargs[typed]; arrayDateFormat = dateISO8601): untyped =
  let nodes = j.getArray(key)
  `t` = newseq[isType](nodes.len)
  for k, n in nodes:
    var s = `isType`()
    loadJson(n,s[],isOf, dateFormat = arrayDateFormat)
    `t`[k] = s
