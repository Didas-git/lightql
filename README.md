# lightql

Very thin and light SQLITE library for zig.

# Installation

Currently zig does not support nested submodules, the recommended way is to add lightql as a submodule.

```sh
git submodule add git@github.com:Didas-git/lightql.git
```

Currently you also need to compile sqlite yourself, this is temporary until I figure out how to build sqlite in zig.

Go to the sqlite submodule inside the lightql's submodule and do the following:

```sh
apt install gcc make tcl-dev
./configure
make sqlite3.c
```

In your `build.zig.zon` file add the following:

```zig
.dependencies = .{
    .lightql = .{
        .path = "lightql", // or the path you saved lightql to
    },
},
```

And import it on your `build.zig` file:

```zig
const lightql = b.dependency("lightql", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("lightql", lightql.module("lightql"));
```
