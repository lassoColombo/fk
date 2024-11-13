

def _fk_cp [cache_dir: string, dry, clip: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let container_path = (input "container path: ") 
  let local_path = (input "local path: ")
  let command = $"kubectl cp ($namespace)/($pod):($container_path) ( $local_path )"
  _fk_execute $command $dry $clip
}



def _fk_fcp [cache_dir: string, dry, clip: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let found = kubectl -n $namespace exec $pod -- find (input "basefolder: ") -maxdepth 5
  let container_path = $found | fzf --header "container path"
  let local_path = (input "local path: ")
  let command = $"kubectl cp ($namespace)/($pod):($container_path) ( $local_path )"
  _fk_execute $command $dry $clip
}
