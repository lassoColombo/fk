source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"

def _fk_edit [kinds, cache_dir: string, dry, clip, run: bool] {
  let kind = _fk_fzf $kinds "kind:"
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  let command = $"kubectl -n ( $namespace ) edit ( $kind ) ( $obj )"
  _fk_execute_async $command $dry $clip $run
}
