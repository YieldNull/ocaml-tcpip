open Core

module Bytes = Caml.Bytes

let set_int buf ~pos ~len value =
  for i = 0 to len - 1 do
    let value = value lsr (8 * (len - 1 - i)) land 0xff in
    Bytes.set buf (pos + i) (char_of_int value)
  done

let set_ipv4 buf ~pos value =
  let len = 4 in
  for i = 0 to len - 1 do
    let value = Int32.to_int_exn @@
      Int32.(land) (Int32.(lsr) value (8 * (len - 1 - i))) 0xffl
    in
    Bytes.set buf (pos + i) (char_of_int value)
  done

let set_byte_arr buf ~pos arr =
  List.iteri arr ~f:(fun i b -> Bytes.set buf (pos + i) (char_of_int b))

let set_bytes buf ~pos data =
  Bytes.blit data 0 buf pos (Bytes.length data)

let int_of_bytes data =
  let len = Bytes.length data in
  String.foldi data ~init:0 ~f:(fun i acc chr ->
      let num = int_of_char chr in
      num lsl ((len - i - 1) * 8) + acc
    )

let checksum packet =
  let sum = ref 0 in
  let len = Bytes.length packet in
  for i = 0 to len - 1 do
    if i mod 2 = 1 then
      let high = int_of_char @@ Bytes.get packet (i - 1) in
      let low = int_of_char @@ Bytes.get packet i in
      let num = high lsl 8 + low in
      sum := !sum + num;
  done;
  if len mod 2 = 1 then begin
    let high = int_of_char @@ Bytes.get packet (len - 1) in
    let num = high lsl 8 in
    sum := !sum + num
  end;
  while !sum lsr 16 > 0 do
    sum := !sum land 0xffff + !sum lsr 16
  done;
  (lnot !sum) land 0xffff

let validate packet = checksum packet = 0
