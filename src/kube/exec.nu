

def _fk_exec [cache_dir: string, dry, clip: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let interactive =  _fk_fzf ["yes", "no"] "interactive:"
  let command = (input "command: ")
  let command = $"kubectl -n ( $namespace ) exec ( $pod ) (if $interactive == 'yes' { '-it' } else { '' }) -- ( $command )"
  _fk_execute_async $command $dry $clip
}
