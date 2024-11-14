source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"


def _fk_get [kinds, cache_dir: string, dry, clip, run: bool] {
  let kind = _fk_fzf $kinds "kind:"
  if $kind == "namespaces" {
    return ( _fk_represent_cmd "kubectl get ns" $dry $clip $run)
  }
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf (["all"] | append $namespaces) "namespace:"
  if $namespace == "all" {
      return ( _fk_represent_cmd $"kubectl get ( $kind ) -A" $dry $clip $run)
  }
  let objs = ["all"] | append (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  if $obj == "all" {
    return ( _fk_represent_cmd $"kubectl -n ( $namespace ) get ( $kind )"  $dry $clip $run)
  }
  mut o = kubectl -n $namespace get $kind $obj -o yaml | from yaml
  mut keys = $o | columns
  mut field = _fk_fzf  ( ["all"] | append $keys ) "field:"
  if $field == "all" {
     return ( _fk_represent_cmd $"kubectl -n ( $namespace ) get ( $kind ) ( $obj )"  $dry $clip $run)
  }
  while $field != "this" {
    $o = $o | get $"($field)"
    let t = $o | describe
    if $t == "string" or $t == "int" or $t == "bool" {
      return ( __fk_represent_var $o $clip $run)
    }
    $keys = $o | columns
    $field = _fk_fzf  ( ["this"] | append $keys ) "field:"
  }
  let repr = _fk_fzf ["json", "yaml", "structured"] "representation:"
  if $repr == "json" { 
    $o = ( $o | to json )
  }
  if $repr == "yaml" { 
    $o = ( $o | to yaml )
  }
  if $dry {
    print $"(ansi yellow_bold)--dry flag is not implemented when getting a specific field in a resource(ansi reset)"
    return
  }
  if $clip {
    _fk_ccp $o
    return
  }
  if not $run {
    print $"(ansi yellow_bold)jsonpath to get a specific field of a resource is not yet implemented. We suggest using the --run flag to run the command(ansi reset)"
    commandline edit --replace $"kubectl -n ( $namespace ) get ( $kind ) ( $obj )"
    return
  }
  $o
}
