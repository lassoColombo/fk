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
  print $"(ansi green_bold)removed cache dir:(ansi magenta) ( $cache_dir )(ansi reset)"
}

def _fk_empty_cache [cache_dir: string] {
  rm -rf $"( $cache_dir )/*"
  print $"(ansi green_bold)emptied cache:(ansi magenta) ( $cache_dir )(ansi reset)"
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
  if ($text | str length) < 400 {
    print $"(ansi green_bold)copied to clipboard:(ansi magenta) ( $text )(ansi reset)"
    return
  }
    print $"(ansi green_bold)copied to clipboard(ansi reset)"
}

def _fk_execute [command: string, dry, clip, run: bool] {
  if $dry {
    if $clip {
      _fk_ccp $command
      return
    }
    return $command
  }
  if $clip {
    _fk_ccp ( nu -c $command )
    return
  }
  if $run {
    print $"(ansi green_bold)executed command:(ansi magenta) ( $command ) (ansi reset)"
    nu -c $command
  }
  commandline edit --replace $command
  return
}


def _fk_execute_async [command: string, dry, clip, run: bool] {
  if $dry {
    if $clip {
      _fk_ccp $command
      return
    }
    return $command
  }
  if $clip {
    print $"(ansi yellow_bold)--clip option alone has no effect when performing an async command."
    print $"If you want to copy the command to the clipboard, you must pass the --dry option as well, but you cannot copy the command output.(ansi reset)"
    return
  }
  if $run {
    print $"(ansi green_bold)executed command:(ansi magenta) ( $command ) (ansi reset)"
    nu -c $command
  }
  commandline edit --replace $command
  return
}
