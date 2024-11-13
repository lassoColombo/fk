def _fk_install [cache_dir: string] {
    mkdir $"($cache_dir)"
    print $"(ansi green_bold)created cache directory in ($cache_dir).\n"
    print $"(ansi yellow_bold)We do not want to automatically modify your config.\n"
    print $"You will need to do the following by hand:(ansi reset)\n"
    print $"(ansi yellow)1) add the following to your config.nu:\n"
    print $"\tconst fk_home_dir = '/path/to/fk/local/repo' (ansi reset)\n"
}

def _fk_uninstall [cache_dir: string] {
  rm -rf $cache_dir
}

def _fk_empty_cache [cache_dir: string] {
  rm -rf $"( $cache_dir )/*"
}

def _fk_fzf [l, h] {
   $l | str join "\n" | fzf --header $h
}

def _fk_multifzf [l, h] {
   $l | str join "\n" | fzf --header $h --multi  --bind 'ctrl-space:toggle+down' | lines
}

def _fk_previewfzf [l, h, p] {
   $l | str join "\n" | fzf --header $h --preview $"'( $p )'" | lines
}

def _fk_ccp [text: string] {
  # :TODO: cross platform support
  $text | pbcopy
}

def _fk_execute [command: string, dry, clip: bool] {
  if $dry {
    if $clip {
      print $"(ansi green)copied to clipboard:(ansi reset) ( $command )"
      _fk_ccp $command
      return
    }
    print $"(ansi green)( $command ) (ansi reset)"
    return
  }
  print $"(ansi green)executed command:(ansi reset) ( $command )"
  let out = ( nu -c $command )
  if $clip {
    print $"(ansi green)copied output to clipboard:(ansi reset)"
    _fk_ccp $out
    return
  }
  $out
}


def _fk_execute_async [command: string, dry, clip: bool] {
  if $dry {
    if $clip {
      print $"(ansi green)copied to clipboard:(ansi reset) ( $command )"
      _fk_ccp $command
      return
    }
    print $"(ansi green)( $command ) (ansi reset)"
    return
  }
  if $clip {
    print $"(ansi yellow)clip option has no effect when performing an async command."
  }
  print $"(ansi green)executed command:(ansi reset) ( $command )"
  nu -c $command 
  return
}
