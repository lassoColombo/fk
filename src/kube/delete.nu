

def _fk_delete [kinds, cache_dir: string, dry, clip: bool] {
  let kind = _fk_fzf $kinds "kind:"
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let chosen_objs =  _fk_multifzf $objs $"($kind)s:"
  let force = _fk_fzf ["yes", "no" ] "force:"
  let command = $"( $chosen_objs ) | each {|obj| kubectl -n ( $namespace ) delete ( $kind ) $obj (if $force == 'yes' { '--force' } else { '' })} "
  _fk_execute $command $dry $clip
}
