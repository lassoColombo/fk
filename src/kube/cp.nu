source $"( $fk_home_dir )/src/utils/fzf.nu"
source $"( $fk_home_dir )/src/utils/execute.nu"
source $"( $fk_home_dir )/src/utils/cache.nu"

def _fk_fcp [cache_dir: string, dry, clip, run: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let kind = _fk_fzf  ["file", "dir"] "field:"
  let basefolder = (input "basefolder: ")
  let name = (input "name: ")
  let found = kubectl -n $namespace exec $pod -- find $basefolder -type (if $kind == 'file' { 'f' } else { 'd' }) -iname $name -maxdepth 6
  let container_path = $found | fzf --header "container path:"
  let local_path = (input "local path: ")
  let command = $"kubectl cp ($namespace)/($pod):($container_path) ( $local_path )"
  _fk_execute $command $dry $clip $run
}
