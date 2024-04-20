interface LZ77
    exposes [encode, decode]
    imports [List]

# Finds the length of the matching section of the two lists, starting at the given indices
matchFrom : List a, U64, List a, U64 -> U64 where a implements Bool.Eq
matchFrom = \first, firstIndex, second, secondIndex ->
  when (List.get first firstIndex, List.get second secondIndex) is
    (Ok a, Ok b) -> if a == b then 1 + matchFrom first (firstIndex + 1) second (secondIndex + 1) else 0
    _ -> 0

# Finds the longest prefix of the first list that exists anywhere in the second list, and returns its offset and length
longestPrefix : List a, List a -> {offset: U64, length: U64} where a implements Bool.Eq
longestPrefix = \a, b ->
  match : U64, {offset: U64, length: U64} -> {offset: U64, length: U64}
  match = \bi, longestSoFar ->
    if bi >= List.len b
      then longestSoFar
      else
        l = matchFrom a 0 b bi
        newLongest = if l > longestSoFar.length && l > 1 then {offset: bi, length: l} else longestSoFar

        match (bi + 1) newLongest
  match 0 {offset: 0, length: 0}


# distanceBack is positive, but is a distance backwards
encodeNext : List a, U64, U64 -> List [Plain a, Repeat ({distanceBack: U64, length: U64})] where a implements Bool.Eq
encodeNext = \data, startOfWindow, indexToEncode ->
  dataLen = List.len data
  if (indexToEncode >= dataLen)
    then []
    else
      l = longestPrefix (List.takeLast data (dataLen - indexToEncode)) (List.sublist data {start:startOfWindow, len: indexToEncode - startOfWindow})
      if l.length > 0
        then List.prepend (encodeNext data (startOfWindow + l.length) (indexToEncode + l.length)) (Repeat {distanceBack: indexToEncode - startOfWindow - l.offset, length: l.length})
        else when List.get data indexToEncode is
              Ok head -> List.prepend (encodeNext data (Num.min (startOfWindow+1) (if indexToEncode >= 1024 then indexToEncode - 1024 else 0)) (indexToEncode+1)) (Plain head)
              # This should never happen, but the compiler doesn't know that:
              # TODO refactor to put the get call at the beginning and remove the len check
              Err _e -> []
  

encode : List a -> List [Plain a, Repeat ({distanceBack: U64, length: U64})] where a implements Bool.Eq
encode = \original ->
  encodeNext original 0 0

decodeNext : List a, [Plain a, Repeat ({distanceBack: U64, length: U64})] -> List a
decodeNext = \soFar, remaining ->
  when remaining is
    Plain x -> List.append soFar x
    Repeat r -> List.concat soFar (List.sublist soFar {start: List.len soFar - r.distanceBack, len: r.length})

decode : List [Plain a, Repeat ({distanceBack: U64, length: U64})] -> List a
decode = \xs -> List.walk xs [] decodeNext
