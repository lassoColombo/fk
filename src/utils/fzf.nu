
def _fk_fzf [l, h] {
   $l | str join "\n" | fzf --header $h
}

def _fk_multifzf [l, h] {
   $l | str join "\n" | fzf --header $h --multi  --bind 'ctrl-space:toggle+down' | lines
}

def _fk_previewfzf [l, h, p] {
   $l | str join "\n" | fzf --header $h --preview $"'( $p )'" | lines
}
