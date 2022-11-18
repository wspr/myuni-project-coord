package = "projtool"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/wspr/myuni-project-coord.git"
}
build = {
   type = "builtin",
   modules = {} -- auto detected within "lua/"
}
dependencies = {
  "csv",
  "binser",
  "penlight",
--  "luadiffer",
}
