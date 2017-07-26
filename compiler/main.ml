open Compile
open Runner
open Printf
open Lexing
open Types
open Str
open Sys
open Filename

let () =

  let infilepath = Sys.argv.(1) in
  let outfilepath = Sys.argv.(2) in
  let infilename = Filename.basename infilepath in

    let help =
      let input_file = open_in infilepath in
      let result = compile_file_to_string infilename input_file in
      match result with
      | Left errs ->
         printf "Errors:\n%s\n" (ExtString.String.join "\n" (print_errors errs))
      | Right program -> 
        let outfile = open_out outfilepath in
        fprintf outfile "%s" program;
        close_out outfile;
    in

    help;
