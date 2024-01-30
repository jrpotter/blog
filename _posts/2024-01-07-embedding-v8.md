---
title: Embedding V8
tags: [c++, cmake, flume, nix]
categories: devlog
image: /assets/img/posters/embedding-v8.png
---

The Flume project diverted away from Elixir to C++ during this past week. In
particular, I was focused on spinning up a small web server that exposes an
[embedded V8](https://v8.dev/docs/embed) instance using
[Mongoose](https://github.com/cesanta/mongoose). The result is a small server
capable of compiling and running arbitrary JavaScript. The next goal is to have
the Elixir/Phoenix backend talking with this worker though the Mongoose-based
API.

Much of the actual work involved in getting everything working was reminding
myself what programming in C++ was like. It has been several years since I've
needed to read C++, let alone write in it. Since I have been writing primarily
functional code, bringing the OOP mindset back to the foreground took a bit of
time. Once I brushed the cobwebs off though, progress was fairly smooth. A few
of the interesting pieces:

## CMake and Nix

I have been using Nix for my package management needs the past few months. With
[flakes](https://nixos.wiki/wiki/Flakes) and
[nix develop](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop.html),
one can spin up a development environment containing all the build tools they
need. This isn't anything new (this premise is what my
[bootstrap](https://git.jrpotter.com/r/bootstrap) project leverages), but how
[CMake's module system](https://cmake.org/cmake/help/latest/command/find_package.html)
interacts with Nix proved to be a pleasant surprise.

Consider the problem of embedding V8. Two problems exist when working within a
traditional environment:

1. There doesn't exist an officially supported CMake module file.
2. V8 actually uses a different build system generator called [gn](https://gn.googlesource.com/gn).

This CMake-incompatibility has led to a few solutions, the most popular I could
find being [v8-cmake](https://github.com/bnoordhuis/v8-cmake). I was not
interested in pulling in an additional dependency just for the sake of embedding
though. Fortunately the v8 derivation found in [nixpkgs](https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/development/libraries/v8/default.nix)
provides a much cleaner solution - it exports a [pkg-config](https://people.freedesktop.org/~dbn/pkg-config-guide.html)
file. With it, embedding V8 is powered by just two lines found in a custom
`FindV8.cmake` file:
```cmake
find_package(PkgConfig)
pkg_check_modules(PC_V8 REQUIRED v8)
```

This works because specifying `pkg-config` in a derivation automatically updates
the `PKG_CONFIG_PATH` environment variable.

## Interoping C/C++

Because Mongoose is a C library and V8 is a C++ library, there were moments
where I needed to interop between the two languages. Though I have encountered
`extern "C"` and the like before, I hadn't sat down and understood what these
two terms together were actually saying. This [language linkage](https://en.cppreference.com/w/cpp/language/language_linkage)
doc helped clarify concepts in my head that I didn't realize were fuzzy.

## V8 Isolates

I was also pleasantly surprised with the V8 library interface. Though I'm sure
it can get complicated, the act of just compiling and running JavaScript was
much simpler than I anticipated. The core of the code looks like the following:
```c++
void process(
  struct mg_connection *conn,
  struct mg_http_message *hm,
  const Payload &payload
) {
  using namespace v8;

  // Sets the isolate for all operations executed within the scope.
  Isolate::Scope isolate_scope(isolate);

  // Automatically deletes every handle within the scope.
  HandleScope handle_scope(isolate);

  // Note `Local`s *must* be managed by `HandleScope`s.
  Local<Context> context = Context::New(isolate);

  // Sets the execution context for all operations executed within the scope.
  Context::Scope context_scope(context);

  Local<String> source;
  if (!String::NewFromUtf8(isolate, payload.code.get()).ToLocal(&source)) {
    return json_response(
      conn, 400, "{\%m: %m}", MG_ESC("error"), MG_ESC("Could not load code")
    );
  }

  Local<Script> script;
  if (!Script::Compile(context, source).ToLocal(&script)) {
    return json_response(
      conn, 400, "{\%m: %m}", MG_ESC("error"), MG_ESC("Could not compile code")
    );
  }

  Local<Value> result;
  if (!script->Run(context).ToLocal(&result)) {
    return json_response(
      conn, 400, "{\%m: %m}", MG_ESC("error"), MG_ESC("Could not run code")
    );
  }
}
```

## Music

As a fun aside, I'm considering including the music I've been listening to while
developing. This past week highlighted:

- [Japanese soft indie/rock, that would be in Goodnight Punpun's playlist](https://www.youtube.com/watch?v=DXKojYz25Gw)
- [Smooth 'Future Bass' Collection For Y'all Vol. 1](https://www.youtube.com/watch?v=SoBAQgl0zbo)
- [ye](https://open.spotify.com/album/2Ek1q2haOnxVqhvVKqMvJe?si=iREJOVFOSG6kSlXbr1Uhkw)
