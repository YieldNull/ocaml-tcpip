mkdir -p _build/src

path="_build/${@: -1}"

if [ ${path: -5} == ".byte" ];then
  ocamlc="-custom,"
else
  ocamlc=""
fi

ocamlbuild -r \
    -use-ocamlfind \
    -tag thread \
    -tag debug \
    -tag bin_annot \
    -tag short_paths \
    -cflags "-w A-4-33-40-41-42-43-34-44" \
    -cflags -strict-sequence \
    -pkgs core,ipaddr,tuntap,async,ppx_cstruct,cstruct,charrua-core.wire \
    -Is src,test \
    $*

if [[ "$path" =~ .*\.(byte|native)$ ]]; then
  name=`basename "$path"`
  rm "$name"
  mv "$path" ./
fi
