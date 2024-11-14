source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"

def _fk_describe [kinds, cache_dir: string, dry, clip, run: bool] {
  let kind = _fk_fzf $kinds "kind:"
  if $kind == "namespaces" {
    return ( _fk_execute "kubectl describe ns" $dry $clip $run)
  }
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf (["all"] | append $namespaces) "namespace:"
  if $namespace == "all" {
      return ( _fk_execute $"kubectl describe ( $kind ) -A" $dry $clip $run)
  }
  let objs = ["all"] | append (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  if $obj == "all" {
    return ( _fk_execute $"kubectl -n ( $namespace ) describe ( $kind )"  $dry $clip $run)
  }
  return ( _fk_execute $"kubectl -n ( $namespace ) describe ( $kind ) ( $obj )"  $dry $clip $run)
}
