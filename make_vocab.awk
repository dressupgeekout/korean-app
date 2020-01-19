BEGIN {
  RS = "\n"
  FS = "\t+"

  print "--[[AUTOMATICALLY GENERATED. DO NOT EDIT.]]"
  print "return {"
}

/^[^#]/ {
  level = $1
  lesson = $2
  korean = $3
  romaja = $4
  english = $5
  printf "{level=%d, lesson=%d, k=\"%s\", r=\"%s\", e=\"%s\"},\n", level, lesson, korean, romaja, english
}

END {
  print "}"
}
