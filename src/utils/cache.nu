def _fk_get_namespaces [cache_dir: string] {
  let asd = open $"($env.HOME)/.kube/config" | from yaml | get 'current-context'
  let cache_dir = $"($cache_dir)/contexts.yaml"
  if ( ls $cache_dir | where name =~ "contexts.yaml" | is-empty ) {
    let current_namespaces = kubectl get ns | detect columns | get NAME
    let contexts = {} | upsert $asd $current_namespaces
    $contexts | to yaml | save --force $cache_dir 
    return $current_namespaces
  }
  mut contexts = open $cache_dir
  if ($contexts | flatten | columns | any {$in == $asd}) {
    let current_namespaces = $contexts | get $asd
    return $current_namespaces
  }
  let current_namespaces = kubectl get ns | detect columns | get NAME
  $contexts = $contexts | upsert $asd $current_namespaces 
  $contexts | to yaml | save --force $cache_dir 
  $current_namespaces 
}
