proc P_prepend_s {txt {str "  "}} {
  set new [list]
  # scrub leading newlines
  regsub {^\n*} $txt {} txt
  # scrub trailing newlines
  regsub {[ \n]*$} $txt {} txt
  foreach l [split $txt "\n"] {
    lappend new [regsub {^ *} $l $str]
  }
  set txt [join $new "\n"]
  return [join $new "\n"]
}
