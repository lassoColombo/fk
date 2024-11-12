def _fk_install [cache_dir: string] {
  mkdir $"($cache_dir)"
}

def _fk_uninstall [cache_dir: string] {
  rm -rf $cache_dir
}

def _fk_empty_cache [d: string] {
  rm -rf $"( $d )/*"
}

def _fk_fzf [l, h] {
   $l | str join "\n" | fzf --header $h
}

def _fk_multifzf [l, h] {
   $l | str join "\n" | fzf --header $h --multi  --bind 'ctrl-space:toggle+down' | lines
}

def _fk_get_namespaces [cache_dir: string] {
  kubectl get ns | detect columns | get NAME
  let current_context = open $"($env.HOME)/.kube/config" | from yaml | get 'current-context'
  let contexts_cache = $"($cache_dir)/contexts.yaml"
  if ( ls $cache_dir | where name =~ "contexts.yaml" | is-empty ) {
    let current_namespaces = kubectl get ns | detect columns | get NAME
    let contexts = {} | upsert $current_context $current_namespaces
    $contexts | to yaml | save --force $contexts_cache 
    return $current_namespaces
  }
  let contexts = open $contexts_cache
  if ($contexts | flatten | columns | any {$in == $current_context}) {
    let current_namespaces = $contexts | get $current_context
    return $current_namespaces
  }
  let current_namespaces = kubectl get ns | detect columns | get NAME
  $contexts | upsert $current_context $current_namespaces 
  $contexts | to yaml | save --force $contexts_cache 
  $current_namespaces 
}

def _fk_logs [cache_dir: string, dry: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let follow =  _fk_fzf ["yes", "no"] "follow:"
  let command = $"kubectl -n ( $namespace ) logs ( $pod ) (if $follow == 'yes' { '-f' } else { '' })"
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  nu -c $command
  return
}

def _fk_represent [command: string, dry: bool] {
  mut c = $command
  let repr = _fk_fzf ["narrow", "wide", "json", "yaml", "structured"] "representation:"
  if $repr == "json" or $repr == "yaml" or $repr == "wide" {
    $c = $"($c) -o ($repr)"
  }
  if $repr == "structured" {
    $c = $"($c) -o yaml"
  }
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  mut out = nu -c $c 
  if $repr == "wide" or $repr == "narrow" {
    $out = $out | detect columns
  }
  if $repr == "structured" {
    $out = $out | from yaml
  }
  return $out
}

def _fk_get [kinds, cache_dir: string, dry: bool] {
  let kind = _fk_fzf $kinds "kind:"
  if $kind == "namespaces" {
    return ( _fk_represent "kubectl get ns" $dry )
  }
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf (["all"] | append $namespaces) "namespace:"
  if $namespace == "all" {
      return ( _fk_represent $"kubectl get ( $kind ) -A" $dry )
  }
  let objs = ["all"] | append (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  if $obj == "all" {
    return ( _fk_represent $"kubectl -n ( $namespace ) get ( $kind )"  $dry )
  }
  _fk_represent $"kubectl -n ( $namespace ) get ( $kind ) ( $obj )"  $dry
}

def _fk_exec [cache_dir: string, dry: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"
  let interactive =  _fk_fzf ["yes", "no"] "interactive:"
  let command = (input "command: ")
  let command = $"kubectl -n ( $namespace ) exec ( $pod ) (if $interactive == 'yes' { '-it' } else { '' }) -- ( $command )"
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  nu -c $command
  return
}

def _fk_cp [cache_dir: string, dry: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"

  let container_path = (input "container path: ") 
  let local_path = (input "local path: ")
  let command = $"kubectl cp ($namespace)/($pod):($container_path) ( $local_path )"
  print $"(ansi green)( $command ) (ansi white)"
  if $dry { 
    return
  }
  nu -c $command
  return
}

def _fk_fcp [cache_dir: string, dry: bool] {
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  _fk_fzf $pods "pod:"

  let found = kubectl -n $namespace exec $pod -- find (input "basefolder: ") -maxdepth 5
  let container_path = $found | fzf --header "container path"

  let local_path = (input "local path: ")
  let command = $"kubectl cp ($namespace)/($pod):($container_path) ( $local_path )"
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  nu -c $command
  return
}

def _fk_delete [kinds, cache_dir: string, dry: bool] {
  let kind = _fk_fzf $kinds "kind:"
  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let chosen_objs =  _fk_multifzf $objs $"($kind)s:"
  print $chosen_objs
  let force = _fk_fzf ["yes", "no" ] "force:"
  let command = $"( $chosen_objs ) | each {|obj| kubectl -n ( $namespace ) delete ( $kind ) $obj (if $force == 'yes' { '--force' } else { '' })} "
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  nu -c $command
  return
}

def _fk_edit [kinds, cache_dir: string, dry: bool] {
  let kind = _fk_fzf $kinds "kind:"

  let namespaces = _fk_get_namespaces $cache_dir
  let namespace = _fk_fzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  _fk_fzf $objs $"($kind)s:"
  let command = $"kubectl -n ( $namespace ) edit ( $kind ) ( $obj )"
  print $"(ansi green)( $command ) (ansi white)"
  if $dry {
    return
  }
  nu -c $command
  return
}

def _fk_run_flags [flags, kinds, cache_dir: string] {
  if $flags.install {
    return ( _fk_install $cache_dir )
  }
  if $flags.uninstall {
    return ( _fk_uninstall $cache_dir )
  }
  if $flags.empty_cache {
    return ( _fk_empty_cache $cache_dir )
  }
  if $flags.logs {
    return ( _fk_logs $cache_dir $flags.dry )
  }
  if $flags.get {
    return ( _fk_get $kinds $cache_dir $flags.dry )
  }
  if $flags.exec {
    return ( _fk_exec $cache_dir $flags.dry )
  }
  if $flags.edit {
    return ( _fk_edit $kinds $cache_dir $flags.dry )
  }
  if $flags.delete {
    return ( _fk_delete $kinds $cache_dir $flags.dry )
  }
  if $flags.copy {
    return ( _fk_cp $cache_dir $flags.dry )
  }
}

def _fk_run_actions [kinds, cache_dir: string, dry: bool] {
  let actions = [
    "logs"
    "get"
    "exec"
    "edit"
    "delete"
    "copy"
    "copy fuzzy"
  ]
  let action = _fk_fzf $actions "action:"
  if $action == "logs" {
    return ( _fk_logs $cache_dir $dry )
  }
  if $action == "get" {
    return ( _fk_get $kinds $cache_dir $dry )
  }
  if $action == "exec" {
    return ( _fk_exec $cache_dir $dry)
  }
  if $action == "edit" {
    return ( _fk_edit $kinds $cache_dir $dry)
  }
  if $action == "delete" {
    return ( _fk_delete $kinds $cache_dir $dry)
  }
  if $action == "copy" {
    return ( _fk_cp $cache_dir $dry)
  }
  if $action == "copy fuzzy" {
    return ( _fk_fcp $cache_dir $dry)
  }
}

def fk [
  --install (-I)
  --uninstall (-X)
  --empty-cache (-R)
  --logs (-l)
  --get (-g)
  --exec (-E)
  --edit (-e)
  --delete (-D)
  --copy (-c)
  --dry (-d)
] {
  let cache_dir = $"($env.HOME)/.cache/fk"
  let kinds = [
    "pod"
    "namespaces"
    "deployment"
    "statefulset"
    "daemonset"
    "job"
    "cronjob"
    "service"
  ]
  mut flags = {
    install: $install,
    uninstall: $uninstall,
    empty_cache: $empty_cache,
    get: $get,
    logs: $logs,
    exec: $exec,
    edit: $edit,
    delete: $delete,
    copy: $copy,
  }
  # _fk_get $kinds $cache_dir $dry
  if ($flags | values | any {|flag| $flag == true }) {
    $flags = $flags | upsert "dry" $dry
    return ( _fk_run_flags $flags $kinds $cache_dir )
  }
  return ( _fk_run_actions $kinds $cache_dir $dry )
} 

