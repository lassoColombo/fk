def _fk_logs [cache_dir: string, dry, clip: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  print $namespace
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let follow =  _fk_fzf ["yes", "no"] "follow:"
  let command = $"kubectl -n ( $namespace ) logs ( $pod ) (if $follow == 'yes' { '-f' } else { '' })"
  _fk_execute_async $command $dry $clip
}
