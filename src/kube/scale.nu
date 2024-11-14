source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"

def _fk_scale [kinds, cache_dir: string, dry, clip, run: bool] {
  let kind = _fk_fzf $kinds "kind:"
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  let current_replicas = kubectl -n $namespace get $kind $obj -o yaml | from yaml | get spec.replicas
  let replicas = input $"replicas {currently ($current_replicas)}: "
  let command = $"kubectl -n ( $namespace ) scale ( $kind ) ( $obj ) --replicas ($replicas)"
  _fk_execute $command $dry $clip $run
}
