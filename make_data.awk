BEGIN {
  RS = "\n"
  FS = "\t+"

  print "return {"
}

/^[^#]/ {
  korean = $1
  romaja = $2
  english = $3
  printf "{k=\"%s\", r=\"%s\", e=\"%s\"},\n", korean, romaja, english
}

END {
  print "}"
}
