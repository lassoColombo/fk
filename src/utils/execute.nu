source $"( $fk_home_dir )/src/utils/fzf.nu"

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

def fk_represent_cmd [command: string, dry, clip, run: bool] {
  mut c = $command
  let repr = _fk_fzf ["narrow", "wide", "json", "yaml", "structured"] "representation:"
  if $repr == "json" or $repr == "yaml" or $repr == "wide" {
    $c = $"($c) -o ($repr)"
  }
  if $repr == "structured" {
    $c = $"($c) -o yaml"
  }
  if $dry {
    if $clip {
      _fk_ccp $c
      return
    }
    return $c
  }
  if $clip {
    _fk_ccp ( _fk_parse (nu -c $c) $repr )
  }
  if $run {
    print $"(ansi green_bold)executed command:(ansi magenta) ( $c ) (ansi reset)"
    return ( _fk_parse (nu -c $c) $repr )
  }
  commandline edit --replace $c
}

def _fk_parse [out, repr] {
  if $repr == "wide" or $repr == "narrow" {
    return ( $out | detect columns )
  }
  if $repr == "structured" {
    print $out
    return ( $out | from yaml )
  }
  $out
}
