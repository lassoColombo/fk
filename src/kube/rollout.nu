source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"

def _fk_rollout [kinds, cache_dir: string, dry, clip, run: bool] {
  let action = _fk_fzf ["history", "restart", "pause", "resume", "status", "undo"] "rollout action:"
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let kind = _fk_fzf $kinds "kind:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  let command = $"kubectl -n ( $namespace ) rollout ( $action ) ( $kind ) ( $obj )"
  _fk_execute $command $dry $clip $run
}
