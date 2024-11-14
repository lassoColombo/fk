source $"( $fk_home_dir )/src/utils/sys.nu"
source $"( $fk_home_dir )/src/kube/cp.nu"
source $"( $fk_home_dir )/src/kube/delete.nu"
source $"( $fk_home_dir )/src/kube/edit.nu"
source $"( $fk_home_dir )/src/kube/exec.nu"
source $"( $fk_home_dir )/src/kube/get.nu"
source $"( $fk_home_dir )/src/kube/logs.nu"
source $"( $fk_home_dir )/src/kube/scale.nu"

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
    return ( _fk_logs $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.get {
    return ( _fk_get $kinds $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.exec {
    return ( _fk_exec $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.edit {
    return ( _fk_edit $kinds $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.delete {
    return ( _fk_delete $kinds $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.copy {
    return ( _fk_fcp $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.copy_fuzzy {
    return ( _fk_fcp $cache_dir $flags.dry $flags.clip $flags.run)
  }
  if $flags.scale {
    return ( _fk_scale $kinds $cache_dir $flags.dry $flags.clip $flags.run)
  }
}

def _fk_run_actions [kinds, cache_dir: string, dry, clip, run: bool] {
  let actions = [
    "logs"
    "get"
    "exec"
    "edit"
    "delete"
    "copy"
    "scale"
  ]
  let action = _fk_fzf $actions "action:"
  if $action == "logs" {
    return ( _fk_logs $cache_dir $dry $clip $run)
  }
  if $action == "get" {
    return ( _fk_get $kinds $cache_dir $dry $clip $run)
  }
  if $action == "exec" {
    return ( _fk_exec $cache_dir $dry $clip $run)
  }
  if $action == "edit" {
    return ( _fk_edit $kinds $cache_dir $dry $clip $run)
  }
  if $action == "delete" {
    return ( _fk_delete $kinds $cache_dir $dry $clip $run)
  }
  if $action == "copy" {
    return ( _fk_fcp $cache_dir $dry $clip $run)
  }
  if $action == "scale" {
    return ( _fk_scale $kinds $cache_dir $dry $clip $run)
  }
}

def fk [
  --install (-I)
  --uninstall (-X)
  --empty-cache (-x)
  --logs (-l)
  --get (-g)
  --exec (-E)
  --edit (-e)
  --delete (-d)
  --copy (-c)
  --scale (-s)

  --dry (-D)
  --clip (-C)
  --run (-R)
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
  if ($flags | values | any {|flag| $flag == true }) {
    $flags = $flags | upsert "dry" $dry
    $flags = $flags | upsert "clip" $clip
    $flags = $flags | upsert "run" $run
    return ( _fk_run_flags $flags $kinds $cache_dir)
  }
  return ( _fk_run_actions $kinds $cache_dir $dry $clip $run)
} 

