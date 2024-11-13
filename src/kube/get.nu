source $"( $fk_home_dir )/src/utils/utils.nu"

def _fk_represent [command: string, dry, clip: bool] {
  mut c = $command
  let repr = _fk_fzf ["narrow", "wide", "json", "yaml", "structured"] "representation:"
  if $repr == "json" or $repr == "yaml" or $repr == "wide" {
    $c = $"($c) -o ($repr)"
  }
  if $repr == "structured" {
    $c = $"($c) -o yaml"
  }
  if $dry {
    print $"(ansi green)( $command ) (ansi reset)"
    return
  }
  if $clip {
    print $"(ansi green)copied to clipboard:(ansi reset) ( $command )"
    _fk_ccp $command
    return
  }
  mut out = nu -c $c 
  if $repr == "wide" or $repr == "narrow" {
    $out = $out | detect columns
  }
  if $repr == "structured" {
    $out = $out | from yaml
  }
  $out
}

def _fk_get [kinds, cache_dir: string, dry, clip: bool] {
  let kind = _fk_fzf $kinds "kind:"
  if $kind == "namespaces" {
    return ( _fk_represent "kubectl get ns" $dry $clip )
  }
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf (["all"] | append $namespaces) "namespace:"
  if $namespace == "all" {
      return ( _fk_represent $"kubectl get ( $kind ) -A" $dry $clip )
  }
  let objs = ["all"] | append (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  if $obj == "all" {
    return ( _fk_represent $"kubectl -n ( $namespace ) get ( $kind )"  $dry $clip )
  }
  mut o = kubectl -n $namespace get $kind $obj -o yaml | from yaml
  mut keys = $o | columns
  mut field = _fk_fzf  ( ["all"] | append $keys ) "field:"
  if $field == "all" {
     return ( _fk_represent $"kubectl -n ( $namespace ) get ( $kind ) ( $obj )"  $dry $clip )
  }
  while $field != "this" {
    $o = $o | get $"($field)"
    let t = $o | describe
    if $t == "string" or $t == "int" or $t == "bool" {
      if $clip {
        print $"(ansi green)copied output to clipboard:(ansi reset) ( $o )"
        _fk_ccp $o
        return
      }
      return $o
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
  if $clip {
    print $"(ansi green)copied output to clipboard:(ansi reset) ( $o )"
    _fk_ccp $o
    return
  }
  $o
}
