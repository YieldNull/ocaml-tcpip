open Ipaddr
open Core
open Async
open Utils

let rec drive reader writer =
  let buf = (Bytes.create Ether_wire.mpkt) in
  Reader.read reader buf
  >>= (fun rs ->
      match rs with
      | Reader.(`Eof) -> failwith "EOF"
      | Reader.(`Ok len) ->
        return
        @@ Ether.handle writer
        @@ Cstruct.sub (Cstruct.of_string buf) 0 len
    )
  >>= fun _ -> drive reader writer

let setup () =
  Unix.openfile Iface.filename ~mode:[Unix.(`Rdwr)]
  >>| fun fd -> Iface.init ()
  >>| function
  | Result.Ok _ -> (* reserve 10 secs for starting wireshark *)
    Clock.run_after (Time.Span.of_int_sec 10) (fun () ->
        let reader = Reader.create fd in
        let writer = Writer.create fd in
        ignore @@ drive reader writer;
        let packet = Dhcp.discover () in
        send writer packet
      ) ()
  | _ -> failwith "initialization failed"

let () =
  ignore @@ setup ();
  never_returns (Scheduler.go ())
