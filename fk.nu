let cache_dir = $"($env.HOME)/.cache/fk"
let actions = [ "logs", "get", "exec", "edit", "delete", "copy", "context", "install_fk"]
let kinds = ["pod", "deployment", "statefulset", "sts", "daemonset" "job", "cronjob", "service"]

def nufzf [l, h] {
   $l | str join "\n" | fzf --header $h
}

def get_namespaces [] {
  let namespaces_cache = $"($cache_dir)/namespaces.yaml"
  let empty = ls $cache_dir | where name =~ "namespaces.yaml" | is-empty
  if not $empty {
    let namespaces = open $namespaces_cache
    return $namespaces
  }
  let namespaces = kubectl get ns | detect columns | get NAME
  $namespaces | to yaml | save --force $namespaces_cache 
  return $namespaces
}

def fk_logs [] {
  let namespaces = get_namespaces
  let namespace = nufzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  nufzf $pods "pod:"
  let follow =  nufzf ["yes", "no"] "follow:"
  kubectl -n $namespace logs $pod (if $follow == "yes" { "-f" } else { "" })
}

def fk_get [] {
  let kind = nufzf $kinds "kind:"

  let namespaces = get_namespaces
  let namespace = nufzf ($namespaces | append "all") "namespace:"
  if $namespace == "all" {
    let repr = nufzf ["narrow", "wide"] "representation:"
    if $repr == "narrow" {
      kubectl get $kind -A
      return null
    }
    kubectl get ($kind) -A -o $repr
    return null
  }

  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME) | append "all"
  let obj =  nufzf $objs $"($kind)s:"
  if $obj == "all" {
    let repr = nufzf ["wide", "narrow"] "representation:"
    if $repr == "narrow" {
      kubectl -n $namespace get $kind
      return null
    }
    kubectl -n $namespace get $kind -o $repr
    return null
  }

  let repr = nufzf ["json", "yaml", "wide", "narrow"] "representation:"
  if $repr == "narrow" {
    kubectl -n $namespace get $kind $obj
  }
  kubectl -n $namespace get $kind $obj -o $repr
}

def fk_exec [] {
  let namespaces = get_namespaces
  let namespace = nufzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  nufzf $pods "pod:"
  let interactive =  nufzf ["yes", "no"] "interactive:"
  let command = (input "command: ")
  kubectl -n $namespace exec $pod (if $interactive == "yes" { "-it" } else { "" }) -- $command
}


def fk_cp [] {
  let namespaces = get_namespaces
  let namespace = nufzf $namespaces "namespace:"
  let pods = kubectl -n $namespace get po | detect columns | get NAME
  let pod =  nufzf $pods "pod:"
  let container_path = (input "container path: ")
  let local_path = (input "local path: ")
  kubectl cp $"($namespace)/($pod):($container_path)" $local_path
}

def fk_delete [] {
  let kind = nufzf $kinds "kind:"

  let namespaces = get_namespaces
  let namespace = nufzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  nufzf $objs $"($kind)s:"

  let force = nufzf ["yes", "no" ] "force:"
  kubectl -n $namespace delete $kind $obj (if $force == "yes" { "--force" } else { "" }) 
}

def fk_edit [] {
  let kind = nufzf $kinds "kind:"

  let namespaces = get_namespaces
  let namespace = nufzf ($namespaces) "namespace:"
  let objs = (kubectl -n $namespace get $kind | detect columns | get NAME)
  let obj =  nufzf $objs $"($kind)s:"

  kubectl -n $namespace edit $kind $obj
}

def fk_ctx [] {
  let contexts = kubectl config get-contexts | detect columns | get NAME
  let context = nufzf $contexts "context:"

  kubectl config set-context $context
}

def fk_install [] {
  mkdir $"($cache_dir)"
}

let action = nufzf $actions "action:"

def main [] {
  if $action == "install_fk" {
    fk_install; return null
  }
  if $action == "logs" {
    fk_logs; return null
  }
  if $action == "get" {
    fk_get; return null
  }
  if $action == "exec" {
    fk_exec; return null
  }
  if $action == "edit" {
    fk_edit; return null
  }
  if $action == "delete" {
    fk_delete; return null
  }
  if $action == "copy" {
    fk_cp; return null
  }
  if $action == "context" {
    fk_ctx; return null
  }
}

